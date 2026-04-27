import Combine
import Foundation
import Speech
import AVFoundation

// MARK: - Parsed Voice Result

struct VoiceInputResult {
    var name: String?
    var gender: String?        // "Male", "Female", "Other"
    var age: Int?
    var relationship: String?
    var occasion: String?
    var budgetMin: Double?
    var budgetMax: Double?
    var tags: [String]
    
    init() { tags = [] }
}

// MARK: - Voice Input Service

@MainActor
class VoiceInputService: NSObject, ObservableObject {
    
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var parsedResult: VoiceInputResult?
    @Published var errorMessage: String?
    @Published var permissionGranted = false
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
        speechRecognizer?.delegate = self
    }
    
    // MARK: - Permissions
    
    func requestPermissions() async {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        let micGranted = await AVAudioApplication.requestRecordPermission()
        
        permissionGranted = (speechStatus == .authorized) && micGranted
        if !permissionGranted {
            errorMessage = "Для голосового ввода необходим доступ к микрофону и распознаванию речи."
        }
    }
    
    // MARK: - Recording
    
    func startRecording() {
        guard !isRecording else { stopRecording(); return }
        
        recognizedText = ""
        parsedResult = nil
        errorMessage = nil
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Распознавание речи недоступно на этом устройстве."
            return
        }
        
        do {
            try setupAudioSession()
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let request = recognitionRequest else { return }
            request.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    Task { @MainActor in
                        self.recognizedText = result.bestTranscription.formattedString
                        if result.isFinal {
                            self.stopRecording()
                        }
                    }
                }
                if let error = error {
                    Task { @MainActor in
                        if self.isRecording {
                            self.errorMessage = "Ошибка: \(error.localizedDescription)"
                            self.stopRecording()
                        }
                    }
                }
            }
        } catch {
            errorMessage = "Ошибка записи: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        let textToParse = recognizedText
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        if !textToParse.isEmpty {
            parseText(textToParse)
        }
    }
    
    private func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - NLP Parsing
    
    func parseText(_ text: String) {
        let lower = text.lowercased()
        var result = VoiceInputResult()
        
        result.name       = parseName(lower)
        result.gender     = parseGender(lower)
        result.age        = parseAge(lower)
        result.relationship = parseRelationship(lower)
        result.occasion   = parseOccasion(lower)
        let (min, max)    = parseBudget(lower)
        result.budgetMin  = min
        result.budgetMax  = max
        result.tags       = parseTags(lower)
        
        parsedResult = result
    }
    
    // MARK: - Parsers
    
    private func parseName(_ text: String) -> String? {
        let patterns = [
            "хочу подарить ([а-яёА-ЯЁ]+)",
            "подарить ([а-яёА-ЯЁ]+)",
            "для ([а-яёА-ЯЁ]+)",
            "дарю ([а-яёА-ЯЁ]+)",
            "подарок ([а-яёА-ЯЁ]+)",
            "подарок для ([а-яёА-ЯЁ]+)",
            "ищу подарок ([а-яёА-ЯЁ]+)",
        ]
        let excluded = ["подруге", "другу", "маме", "папе", "брату", "сестре",
                        "мужу", "жене", "коллеге", "бабушке", "дедушке",
                        "мужчине", "женщине", "девушке", "парню"]
        for pattern in patterns {
            if let match = text.firstMatch(pattern: pattern, group: 1) {
                let name = match.capitalized
                if !excluded.contains(name.lowercased()) {
                    // Убираем окончания дательного падежа (-у, -е, -ю)
                    let normalized = normalizeName(name)
                    return normalized
                }
            }
        }
        return nil
    }

    private func normalizeName(_ name: String) -> String {
        // Александру → Александр, Маше → Маша и т.д.
        let endings: [(suffix: String, replacement: String)] = [
            ("ру", "р"),   // Александру → Александр
            ("ше", "ша"),  // Маше → Маша
            ("не", "на"),  // Анне → Анна
            ("ле", "ла"),  // Юле → Юля (приблизительно)
            ("ю", "я"),    // Юлю → Юля
            ("е", "а"),    // общий случай
        ]
        for e in endings {
            if name.lowercased().hasSuffix(e.suffix) && name.count > e.suffix.count + 2 {
                let base = String(name.dropLast(e.suffix.count))
                return base + e.replacement
            }
        }
        return name
    }
    
    private func parseGender(_ text: String) -> String? {
        let maleWords = ["мужчина", "мужчине", "парень", "парню", "мужу", "брату",
                         "папе", "дедушке", "другу", "коллеге мужчине", "он"]
        let femaleWords = ["женщина", "женщине", "девушка", "девушке", "жене", "сестре",
                           "маме", "бабушке", "подруге", "она"]
        
        for w in femaleWords { if text.contains(w) { return "Female" } }
        for w in maleWords   { if text.contains(w) { return "Male" } }
        return nil
    }
    
    private func parseAge(_ text: String) -> Int? {
        // "35 лет", "ему 25", "40-летие"
        let patterns = ["(\\d+) лет", "ему (\\d+)", "ей (\\d+)", "(\\d+)-лети"]
        for pattern in patterns {
            if let match = text.firstMatch(pattern: pattern, group: 1),
               let age = Int(match), age > 0, age < 120 {
                return age
            }
        }
        return nil
    }
    
    private func parseRelationship(_ text: String) -> String? {
        let map: [(keywords: [String], value: String)] = [
            (["мама", "маме", "мамы"],                 "Мама"),
            (["папа", "папе", "папы"],                 "Папа"),
            (["брат", "брату", "брата"],               "Брат"),
            (["сестра", "сестре", "сестры"],           "Сестра"),
            (["друг", "другу", "друга"],               "Друг"),
            (["подруга", "подруге", "подруги"],        "Подруга"),
            (["жена", "жене", "жены"],                 "Жена"),
            (["муж", "мужу", "мужа"],                  "Муж"),
            (["коллега", "коллеге", "коллеги"],        "Коллега"),
            (["бабушка", "бабушке"],                   "Бабушка"),
            (["дедушка", "дедушке"],                   "Дедушка"),
            (["родственник", "родственнику"],          "Родственник"),
            (["начальник", "начальнику", "босс"],      "Начальник"),
            (["ребёнок", "ребенок", "ребёнку", "ребенку", "дети", "детям"], "Ребёнок"),
        ]
        for entry in map {
            for kw in entry.keywords {
                if text.contains(kw) { return entry.value }
            }
        }
        return nil
    }
    
    private func parseOccasion(_ text: String) -> String? {
        let map: [(keywords: [String], value: String)] = [
            (["день рождения", "дня рождения", "днюха"],            "День рождения"),
            (["новый год", "новым годом"],                          "Новый год"),
            (["свадьба", "свадьбу", "свадьбы"],                     "Свадьба"),
            (["юбилей", "юбилея"],                                  "Юбилей"),
            (["8 марта", "восьмое марта", "женский день"],          "8 марта"),
            (["23 февраля", "двадцать третье февраля"],             "23 февраля"),
            (["выпускной", "окончание"],                            "Выпускной"),
            (["корпоратив", "корпоративный"],                       "Корпоратив"),
            (["просто так", "без повода"],                          "Просто так"),
        ]
        for entry in map {
            for kw in entry.keywords {
                if text.contains(kw) { return entry.value }
            }
        }
        return nil
    }
    
    private func parseBudget(_ text: String) -> (Double?, Double?) {
        // "бюджет 3000", "от 1000 до 5000", "до 2000", "примерно 4000"
        
        // "от X до Y"
        if let from = text.firstMatch(pattern: "от (\\d+)", group: 1),
           let to   = text.firstMatch(pattern: "до (\\d+)", group: 1),
           let minV = Double(from), let maxV = Double(to) {
            return (minV, maxV)
        }
        
        // "до X"
        if let to = text.firstMatch(pattern: "до (\\d+)", group: 1),
           let maxV = Double(to) {
            return (nil, maxV)
        }
        
        // "бюджет X" / "примерно X" / "около X" → ±30%
        let singlePatterns = ["бюджет (\\d+)", "примерно (\\d+)", "около (\\d+)", "(\\d+) рублей", "(\\d+) руб", "(\\d+) тысяч"]
        for pattern in singlePatterns {
            if let match = text.firstMatch(pattern: pattern, group: 1),
               let val = Double(match) {
                let amount = pattern.contains("тысяч") ? val * 1000 : val
                return (amount * 0.7, amount * 1.3)
            }
        }
        
        return (nil, nil)
    }
    
    private func parseTags(_ text: String) -> [String] {
        let tagMap: [(keywords: [String], tag: String)] = [
            (["спорт", "спортивн", "фитнес", "тренировк"],         "Спорт"),
            (["книг", "читает", "чтени"],                           "Книги"),
            (["музык", "гитар", "наушник"],                        "Музыка"),
            (["игр", "геймер", "приставк", "playstation", "xbox"], "Игры"),
            (["кулинар", "готовит", "повар", "кухн"],              "Кулинария"),
            (["путешеств", "туризм", "поездк"],                    "Путешествия"),
            (["технолог", "гаджет", "техник"],                     "Технологии"),
            (["красота", "косметик", "уход"],                      "Красота"),
            (["кино", "фильм", "сериал"],                          "Кино"),
            (["искусство", "рисует", "творч"],                     "Искусство"),
            (["природа", "дача", "сад", "цветы"],                  "Природа"),
        ]
        var tags: [String] = []
        for entry in tagMap {
            for kw in entry.keywords {
                if text.contains(kw) { tags.append(entry.tag); break }
            }
        }
        return tags
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension VoiceInputService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available { self.errorMessage = "Распознавание речи временно недоступно." }
        }
    }
}

// MARK: - String Regex Helper

private extension String {
    func firstMatch(pattern: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(self.startIndex..., in: self)
        guard let match = regex.firstMatch(in: self, options: [], range: range),
              let groupRange = Range(match.range(at: group), in: self) else { return nil }
        return String(self[groupRange])
    }
}
