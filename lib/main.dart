import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

void main() => runApp(const AfinadorApp());

const List<String> noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
];

const List<String> vogais = ['A', 'E', 'I', 'O', 'U'];

const List<int> registrosVocais = [1, 2, 3, 4, 5, 6];

// Formantes para síntese de vogal (F1, F2, F3 em Hz)
const Map<String, List<double>> formantes = {
  'A': [730, 1090, 2440],
  'E': [530, 1840, 2480],
  'I': [270, 2290, 3010],
  'O': [570, 840, 2410],
  'U': [300, 870, 2240],
};

// ====== PALETA "TECLADO VIRTUAL" ======
const Color pianoWhite = Color(0xFFFFFFFF);
const Color pianoIce = Color(0xFFF5F5F5);
const Color pianoBlack = Color(0xFF111111);
const Color pianoGray = Color(0xFF555555);
const Color pianoCorrect = Color(0xFF22C55E);
const Color pianoWrong = Color(0xFFEF4444);

enum Dificuldade {
  iniciante('Iniciantes', 25, 50, 'Iniciante'),
  amador('Amadores', 15, 30, 'Amador'),
  profissional('Profissionais', 5, 15, 'Profissional');

  final String nome;
  final int verde;
  final int laranja;
  final String subtitulo;
  const Dificuldade(this.nome, this.verde, this.laranja, this.subtitulo);
}

class SequenciaDef {
  final String nome;
  final List<int> semitons;
  const SequenciaDef(this.nome, this.semitons);
}

// ====== TODAS AS ESCALAS ORGANIZADAS POR CATEGORIA ======
final Map<String, Map<String, SequenciaDef>> _categorias = {
  '🎵 Modos Gregos': {
    'Maior (Jônico)': const SequenciaDef('Maior', [0, 2, 4, 5, 7, 9, 11, 12]),
    'Dórico': const SequenciaDef('Dórico', [0, 2, 3, 5, 7, 9, 10, 12]),
    'Frígio': const SequenciaDef('Frígio', [0, 1, 3, 5, 7, 8, 10, 12]),
    'Lídio': const SequenciaDef('Lídio', [0, 2, 4, 6, 7, 9, 11, 12]),
    'Mixolídio': const SequenciaDef('Mixolídio', [0, 2, 4, 5, 7, 9, 10, 12]),
    'Eólio (Menor Natural)': const SequenciaDef('Eólio', [0, 2, 3, 5, 7, 8, 10, 12]),
    'Lócrio': const SequenciaDef('Lócrio', [0, 1, 3, 5, 6, 8, 10, 12]),
  },
  ' Escalas Menores': {
    'Menor Harmônica': const SequenciaDef('Menor Harm.', [0, 2, 3, 5, 7, 8, 11, 12]),
    'Menor Melódica': const SequenciaDef('Menor Mel.', [0, 2, 3, 5, 7, 9, 11, 12]),
    'Menor Húngara': const SequenciaDef('Menor Húng.', [0, 2, 3, 6, 7, 8, 11, 12]),
  },
  '🎸 Pentatônicas e Blues': {
    'Maior Pentatônica': const SequenciaDef('Maior Pent.', [0, 2, 4, 7, 9, 12]),
    'Menor Pentatônica': const SequenciaDef('Menor Pent.', [0, 3, 5, 7, 10, 12]),
    'Blues': const SequenciaDef('Blues', [0, 3, 5, 6, 7, 10, 12]),
  },
  '🌍 Étnicas / Exóticas': {
    'Cigana': const SequenciaDef('Cigana', [0, 2, 3, 6, 7, 8, 11, 12]),
    'Árabe': const SequenciaDef('Árabe', [0, 1, 4, 5, 7, 8, 11, 12]),
    'Bizantina': const SequenciaDef('Bizantina', [0, 1, 4, 5, 7, 8, 11, 12]),
    'Japonesa (Hirajoshi)': const SequenciaDef('Hirajoshi', [0, 2, 3, 7, 8, 12]),
    'Japonesa (In)': const SequenciaDef('In', [0, 1, 5, 7, 8, 12]),
    'Indiana': const SequenciaDef('Indiana', [0, 1, 4, 5, 7, 8, 10, 12]),
    'Espanhola': const SequenciaDef('Espanhola', [0, 1, 4, 5, 7, 9, 10, 12]),
    'Napolitana Maior': const SequenciaDef('Nap. Maior', [0, 1, 3, 5, 7, 9, 11, 12]),
    'Napolitana Menor': const SequenciaDef('Nap. Menor', [0, 1, 3, 5, 7, 8, 10, 12]),
  },
  ' Simétricas': {
    'Tons Inteiros': const SequenciaDef('Tons Int.', [0, 2, 4, 6, 8, 10, 12]),
    'Cromática': const SequenciaDef('Cromática', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
    'Diminuta (T/S)': const SequenciaDef('Dim. T/S', [0, 2, 3, 5, 6, 8, 9, 11, 12]),
    'Diminuta (S/T)': const SequenciaDef('Dim. S/T', [0, 1, 3, 4, 6, 7, 9, 10, 12]),
    'Bebop Dominante': const SequenciaDef('Bebop Dom.', [0, 2, 4, 5, 7, 9, 10, 11, 12]),
    'Bebop Maior': const SequenciaDef('Bebop Maior', [0, 2, 4, 5, 7, 8, 9, 11, 12]),
  },
  '🎹 Arpejos e Tríades': {
    'Tríade Maior': const SequenciaDef('Triade Maior', [0, 4, 7]),
    'Tríade Menor': const SequenciaDef('Triade Menor', [0, 3, 7]),
    'Tríade Aumentada': const SequenciaDef('Triade Aum.', [0, 4, 8]),
    'Tríade Diminuta': const SequenciaDef('Triade Dim.', [0, 3, 6]),
    'Arpejo Maior': const SequenciaDef('Arpejo Maior', [0, 4, 7, 12]),
    'Arpejo Menor': const SequenciaDef('Arpejo Menor', [0, 3, 7, 12]),
    'Arpejo Dominante (7)': const SequenciaDef('Dom. 7', [0, 4, 7, 10, 12]),
    'Arpejo Maior 7M': const SequenciaDef('Maior 7M', [0, 4, 7, 11, 12]),
    'Arpejo Menor 7m': const SequenciaDef('Menor 7m', [0, 3, 7, 10, 12]),
    'Arpejo Diminuto': const SequenciaDef('Diminuto', [0, 3, 6, 9, 12]),
    'Arpejo Aumentado': const SequenciaDef('Aumentado', [0, 4, 8, 12]),
  },
  '🎯 Intervalos': {
    'Segunda menor': const SequenciaDef('2m', [0, 1, 0]),
    'Segunda maior': const SequenciaDef('2M', [0, 2, 0]),
    'Terça menor': const SequenciaDef('3m', [0, 3, 0]),
    'Terça maior': const SequenciaDef('3M', [0, 4, 0]),
    'Quarta justa': const SequenciaDef('4J', [0, 5, 0]),
    'Trítono': const SequenciaDef('TT', [0, 6, 0]),
    'Quinta justa': const SequenciaDef('5J', [0, 7, 0]),
    'Sexta menor': const SequenciaDef('6m', [0, 8, 0]),
    'Sexta maior': const SequenciaDef('6M', [0, 9, 0]),
    'Sétima menor': const SequenciaDef('7m', [0, 10, 0]),
    'Sétima maior': const SequenciaDef('7M', [0, 11, 0]),
    'Oitava': const SequenciaDef('8va', [0, 12, 0]),
  },
  '🎼 Melodias': {
    'Dó-Ré-Mi-Fá-Sol': const SequenciaDef('Subida', [0, 2, 4, 5, 7]),
    'Sol-Fa-Mi-Ré-Dó': const SequenciaDef('Descida', [7, 5, 4, 2, 0]),
    'Arco-Íris': const SequenciaDef('Arco', [0, 2, 4, 5, 7, 5, 4, 2, 0]),
    'Escalada completa': const SequenciaDef('Escalada', [0, 2, 4, 5, 7, 9, 11, 12, 11, 9, 7, 5, 4, 2, 0]),
  },
};

SequenciaDef _buscarEscala(String nome) {
  for (final cat in _categorias.values) {
    if (cat.containsKey(nome)) return cat[nome]!;
  }
  return _categorias.values.first.values.first;
}

double _freqDaNota(int midi) => 440.0 * math.pow(2, (midi - 69) / 12).toDouble();

class NotaSequencia {
  final String nota;
  final int oitava;
  const NotaSequencia(this.nota, this.oitava);

  String get nome => nota.endsWith('#') ? '$nota${oitava}' : '$nota$oitava';
  int get midi => 12 * (oitava + 1) + noteNames.indexOf(nota);
  double get freq => _freqDaNota(midi);
}

class ResultadoSequencia {
  final String alvo;
  final String cantada;
  final int cents;
  final bool notaCerta;
  final bool afinado;
  final bool cantou;
  const ResultadoSequencia({
    required this.alvo,
    required this.cantada,
    required this.cents,
    required this.notaCerta,
    required this.afinado,
    required this.cantou,
  });
}

enum FaseSequencia { parado, contagem, tocando, finalizado, ouvindo }

enum ModoVogal { fixa, todas }

class AfinadorApp extends StatefulWidget {
  const AfinadorApp({super.key});
  @override
  State<AfinadorApp> createState() => _AfinadorAppState();
}

class _AfinadorAppState extends State<AfinadorApp> {
  // Nota alvo (modo livre)
  String _notaSimples = 'F';
  int _oitava = 4;
  String _notaAlvo = 'F4';
  double _freqAlvo = 349.23;
  String _vogalAfinador = 'A';

  Dificuldade _dificuldade = Dificuldade.amador;

  bool _ouvindo = false;
  double _freqCantada = 0;
  String _notaCantada = '-';
  double _desvioAlvo = 0;

  // Áudio
  web.AudioContext? _audioCtx;
  web.MediaStream? _stream;
  web.AnalyserNode? _analyser;
  Float32List _dataArray = Float32List(2048);
  Timer? _timerDeteccao;
  Timer? _timerSequencia;

  // Sequência
  String _sequenciaSelecionada = 'Maior (Jônico)';
  String _notaRaiz = 'C';
  int _registroVocal = 3;
  String _vogalSelecionada = 'A';
  ModoVogal _modoVogal = ModoVogal.fixa;
  double _bpm = 60;
  FaseSequencia _fase = FaseSequencia.parado;
  int _indiceNotaAtual = -1;
  int _batidaContagem = 0;
  List<NotaSequencia> _sequenciaAtual = const [];
  final List<double> _janelaFreqs = [];
  final List<ResultadoSequencia> _resultados = [];

  // Gravação
  web.MediaRecorder? _mediaRecorder;
  web.MediaStreamAudioDestinationNode? _destinoGravacao;
  final List<web.Blob> _audioChunks = [];
  String? _audioUrl;
  bool _gravando = false;
  String _mimeType = 'audio/webm';
  String _extensaoAudio = 'webm';

  static const Map<String, double> _presetsBpm = {
    'Lento': 50,
    'Normal': 70,
    'Rápido': 100,
  };

  @override
  void initState() {
    super.initState();
    _detectarFormatoGravacao();
  }

  void _detectarFormatoGravacao() {
    if (web.MediaRecorder.isTypeSupported('audio/mp3')) {
      _mimeType = 'audio/mp3';
      _extensaoAudio = 'mp3';
    } else if (web.MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
      _mimeType = 'audio/webm;codecs=opus';
      _extensaoAudio = 'webm';
    } else if (web.MediaRecorder.isTypeSupported('audio/webm')) {
      _mimeType = 'audio/webm';
      _extensaoAudio = 'webm';
    } else if (web.MediaRecorder.isTypeSupported('audio/mp4')) {
      _mimeType = 'audio/mp4';
      _extensaoAudio = 'm4a';
    } else {
      _mimeType = '';
      _extensaoAudio = 'bin';
    }
  }

  List<NotaSequencia> _gerarSequencia() {
    final def = _buscarEscala(_sequenciaSelecionada);
    final midiBase = _midiNotaRaiz();
    return def.semitons.map((st) {
      final midi = midiBase + st;
      final nome = noteNames[(midi % 12 + 12) % 12];
      final oitava = (midi ~/ 12) - 1;
      return NotaSequencia(nome, oitava);
    }).toList();
  }

  int _midiNotaRaiz() {
    final indice = noteNames.indexOf(_notaRaiz);
    return 12 * (_registroVocal + 1) + indice;
  }

  void _atualizarAlvo() {
    final indice = noteNames.indexOf(_notaSimples);
    final midi = 12 * (_oitava + 1) + indice;
    _freqAlvo = 440.0 * math.pow(2, (midi - 69) / 12).toDouble();
    _notaAlvo = '$_notaSimples$_oitava';
    setState(() {});
  }

  Future<void> _setupMicrofone() async {
    _audioCtx ??= web.AudioContext();
    _stream = await web.window.navigator.mediaDevices
        .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
        .toDart;

    _destinoGravacao = _audioCtx!.createMediaStreamDestination();

    final source = _audioCtx!.createMediaStreamSource(_stream!);
    _analyser = _audioCtx!.createAnalyser();
    _analyser!.fftSize = 2048;
    source.connect(_analyser!);

    source.connect(_destinoGravacao!);

    _dataArray = Float32List(2048);
  }

  void _tocarClick() {
    final ctx = _audioCtx!;
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'square';
    osc.frequency.value = 1000;
    final now = ctx.currentTime;
    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.06);
    osc.connect(gain);
    gain.connect(ctx.destination);
    if (_destinoGravacao != null) gain.connect(_destinoGravacao!);
    osc.start(now);
    osc.stop(now + 0.07);
  }

  void _tocarCue(double freq, {double dur = 0.4}) {
    final ctx = _audioCtx!;
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = freq;
    final now = ctx.currentTime;
    gain.gain.setValueAtTime(0, now);
    gain.gain.linearRampToValueAtTime(0.3, now + 0.02);
    gain.gain.linearRampToValueAtTime(0, now + dur);
    osc.connect(gain);
    gain.connect(ctx.destination);
    if (_destinoGravacao != null) gain.connect(_destinoGravacao!);
    osc.start(now);
    osc.stop(now + dur);
  }

  void _tocarVogal(double freq, String vogal, {double dur = 1.5}) {
    final ctx = _audioCtx!;
    final now = ctx.currentTime;
    final form = formantes[vogal]!;

    final osc = ctx.createOscillator();
    osc.type = 'sawtooth';
    osc.frequency.value = freq;

    final f1 = ctx.createBiquadFilter();
    f1.type = 'bandpass';
    f1.frequency.value = form[0];
    f1.Q.value = 10;

    final f2 = ctx.createBiquadFilter();
    f2.type = 'bandpass';
    f2.frequency.value = form[1];
    f2.Q.value = 10;

    final f3 = ctx.createBiquadFilter();
    f3.type = 'bandpass';
    f3.frequency.value = form[2];
    f3.Q.value = 10;

    final g1 = ctx.createGain();
    g1.gain.value = 1.0;
    final g2 = ctx.createGain();
    g2.gain.value = 0.8;
    final g3 = ctx.createGain();
    g3.gain.value = 0.6;

    final masterGain = ctx.createGain();
    masterGain.gain.setValueAtTime(0, now);
    masterGain.gain.linearRampToValueAtTime(0.25, now + 0.05);
    masterGain.setValueAtTime(0.25, now + dur - 0.1);
    masterGain.gain.linearRampToValueAtTime(0, now + dur);

    osc.connect(f1);
    osc.connect(f2);
    osc.connect(f3);
    f1.connect(g1);
    f2.connect(g2);
    f3.connect(g3);
    g1.connect(masterGain);
    g2.connect(masterGain);
    g3.connect(masterGain);
    masterGain.connect(ctx.destination);
    if (_destinoGravacao != null) masterGain.connect(_destinoGravacao!);

    osc.start(now);
    osc.stop(now + dur);
  }

  void _tocarNota() {
    _audioCtx ??= web.AudioContext();
    _tocarVogal(_freqAlvo, _vogalAfinador);
  }

  void _iniciarGravacao() {
    if (_stream == null || _destinoGravacao == null || _mimeType.isEmpty) return;

    if (_audioUrl != null) {
      web.URL.revokeObjectURL(_audioUrl!);
      _audioUrl = null;
    }
    _audioChunks.clear();
    _gravando = true;
    setState(() {});

    final options = web.MediaRecorderOptions(mimeType: _mimeType);
    _mediaRecorder = web.MediaRecorder(_destinoGravacao!.stream, options);

    _mediaRecorder!.ondataavailable = ((web.Event event) {
      final blobEvent = event as web.BlobEvent;
      if (blobEvent.data != null) _audioChunks.add(blobEvent.data!);
    }).toJS;

    _mediaRecorder!.onstop = ((web.Event event) {
      if (_audioChunks.isEmpty) {
        setState(() => _gravando = false);
        return;
      }
      final propBag = web.BlobPropertyBag(type: _mimeType);
      final blob = web.Blob(_audioChunks.toJS, propBag);
      final url = web.URL.createObjectURL(blob);
      setState(() {
        _audioUrl = url;
        _gravando = false;
      });
    }).toJS;

    _mediaRecorder!.start();
  }

  void _pararGravacao() {
    if (_mediaRecorder != null && _mediaRecorder!.state != 'inactive') {
      _mediaRecorder!.stop();
    }
    _mediaRecorder = null;
  }

  void _ouvirGravacao() {
    if (_audioUrl == null) return;
    final audio = web.document.createElement('audio') as web.HTMLAudioElement
      ..src = _audioUrl!
      ..controls = true
      ..style.display = 'block'
      ..style.marginBottom = '8px';
    final existente = web.document.getElementById('player-gravacao');
    if (existente != null) existente.remove();
    audio.id = 'player-gravacao';
    web.document.body!.appendChild(audio);
    audio.play();
  }

  void _baixarGravacao() {
    if (_audioUrl == null) return;
    final nome =
        'afinador_${DateTime.now().millisecondsSinceEpoch}.$_extensaoAudio';
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = _audioUrl!
      ..download = nome
      ..style.display = 'none';
    web.document.body!.appendChild(anchor);
    anchor.click();
    anchor.remove();
  }

  void _processar(double freq) {
    final midi = 69 + 12 * (math.log(freq / 440.0) / math.ln2);
    final midiRounded = midi.round();
    final nome = noteNames[(midiRounded % 12 + 12) % 12];
    final oitava = (midiRounded ~/ 12) - 1;
    final desvio = 1200 * math.log(freq / _freqAlvo) / math.ln2;
    setState(() {
      _freqCantada = freq;
      _notaCantada = '$nome$oitava';
      _desvioAlvo = desvio;
    });
  }

  double _detectarPitch(Float32List buffer, double sampleRate) {
    final size = buffer.length;
    var rms = 0.0;
    for (var i = 0; i < size; i++) {
      rms += buffer[i] * buffer[i];
    }
    rms = math.sqrt(rms / size);
    if (rms < 0.01) return 0;
    int bestLag = -1;
    double bestCorr = 0;
    final minLag = 30;
    final maxLag = (sampleRate / 80).floor();
    for (var lag = minLag; lag < maxLag; lag++) {
      double corr = 0;
      for (var i = 0; i < size - lag; i++) {
        corr += buffer[i] * buffer[i + lag];
      }
      if (corr > bestCorr) {
        bestCorr = corr;
        bestLag = lag;
      }
    }
    return bestLag > 0 ? sampleRate / bestLag : 0;
  }

  Future<void> _iniciarOuvir() async {
    await _setupMicrofone();
    _timerDeteccao = Timer.periodic(const Duration(milliseconds: 40), (_) {
      _analyser!.getFloatTimeDomainData(_dataArray.toJS);
      final freq = _detectarPitch(_dataArray, _audioCtx!.sampleRate.toDouble());
      if (freq > 0) _processar(freq);
    });
    setState(() => _ouvindo = true);
  }

  String _vogalDaNota(int indice) {
    if (_modoVogal == ModoVogal.fixa) return _vogalSelecionada;
    return vogais[indice % vogais.length];
  }

  Future<void> _ouvirSequencia() async {
    _audioCtx ??= web.AudioContext();
    _sequenciaAtual = _gerarSequencia();
    _fase = FaseSequencia.ouvindo;
    _indiceNotaAtual = 0;
    setState(() {});

    final beatMs = (60000 / _bpm).round();
    _tocarNotaSequencia(0, tocarClick: false);
    _timerSequencia = Timer.periodic(Duration(milliseconds: beatMs), (_) {
      setState(() {
        _indiceNotaAtual++;
        if (_indiceNotaAtual < _sequenciaAtual.length) {
          _tocarNotaSequencia(_indiceNotaAtual, tocarClick: false);
        } else {
          _timerSequencia?.cancel();
          _fase = FaseSequencia.finalizado;
          _indiceNotaAtual = -1;
        }
      });
    });
  }

  Future<void> _iniciarSequencia() async {
    await _setupMicrofone();
    _iniciarGravacao();

    _sequenciaAtual = _gerarSequencia();
    _resultados.clear();
    _janelaFreqs.clear();
    _fase = FaseSequencia.contagem;
    _batidaContagem = 4;
    _indiceNotaAtual = -1;
    setState(() {});

    _timerDeteccao = Timer.periodic(const Duration(milliseconds: 40), (_) {
      _analyser!.getFloatTimeDomainData(_dataArray.toJS);
      final freq = _detectarPitch(_dataArray, _audioCtx!.sampleRate.toDouble());
      if (freq > 0) {
        _processar(freq);
        if (_fase == FaseSequencia.tocando) _janelaFreqs.add(freq);
      }
    });

    final beatMs = (60000 / _bpm).round();
    _timerSequencia = Timer.periodic(Duration(milliseconds: beatMs), (_) {
      setState(() {
        switch (_fase) {
          case FaseSequencia.contagem:
            _tocarClick();
            _batidaContagem--;
            if (_batidaContagem <= 0) {
              _fase = FaseSequencia.tocando;
              _indiceNotaAtual = 0;
              _tocarNotaSequencia(0);
            }
            break;
          case FaseSequencia.tocando:
            _avaliarJanela(_sequenciaAtual[_indiceNotaAtual]);
            _indiceNotaAtual++;
            if (_indiceNotaAtual < _sequenciaAtual.length) {
              _tocarNotaSequencia(_indiceNotaAtual);
            } else {
              _fase = FaseSequencia.finalizado;
              _pararTudo();
            }
            break;
          default:
            break;
        }
      });
    });
  }

  void _tocarNotaSequencia(int i, {bool tocarClick = true}) {
    final n = _sequenciaAtual[i];
    if (tocarClick) _tocarClick();
    _freqAlvo = n.freq;
    _notaAlvo = n.nome;
    final dur = 60000 / _bpm / 1000 * 0.8;
    final vogal = _vogalDaNota(i);
    _tocarVogal(n.freq, vogal, dur: dur);
  }

  void _avaliarJanela(NotaSequencia alvo) {
    final freqs = _janelaFreqs.where((f) => f > 0).toList();
    _janelaFreqs.clear();
    if (freqs.isEmpty) {
      _resultados.add(ResultadoSequencia(
        alvo: alvo.nome, cantada: '—', cents: 0,
        notaCerta: false, afinado: false, cantou: false));
      return;
    }
    freqs.sort();
    final mediana = freqs[freqs.length ~/ 2];
    final cents = (1200 * math.log(mediana / alvo.freq) / math.ln2).round();

    final counts = <int, int>{};
    for (final f in freqs) {
      final m = (69 + 12 * (math.log(f / 440.0) / math.ln2)).round();
      counts[m] = (counts[m] ?? 0) + 1;
    }
    int midi = counts.keys.first;
    int best = 0;
    counts.forEach((k, v) {
      if (v > best) { best = v; midi = k; }
    });
    final nome = noteNames[(midi % 12 + 12) % 12];
    final oitava = (midi ~/ 12) - 1;
    final cantada = '$nome$oitava';
    final notaCerta = midi == alvo.midi;
    final afinado = notaCerta && cents.abs() <= _dificuldade.verde;

    _resultados.add(ResultadoSequencia(
      alvo: alvo.nome, cantada: cantada, cents: cents,
      notaCerta: notaCerta, afinado: afinado, cantou: true));
  }

  void _pararTudo() {
    _pararGravacao();
    _timerDeteccao?.cancel();
    _timerSequencia?.cancel();
    _stream?.getTracks().toDart.forEach((t) => t.stop());
    _audioCtx?.close();
    _audioCtx = null;
    _stream = null;
    _destinoGravacao = null;
    _ouvindo = false;
    setState(() {});
  }

  void _parar() {
    _pararTudo();
    _fase = FaseSequencia.parado;
    _indiceNotaAtual = -1;
  }

  @override
  void dispose() {
    _timerDeteccao?.cancel();
    _timerSequencia?.cancel();
    if (_audioUrl != null) web.URL.revokeObjectURL(_audioUrl!);
    super.dispose();
  }

  Color _corDesvio(double desvio) {
    final abs = desvio.abs();
    if (abs <= _dificuldade.verde) return pianoCorrect;
    if (abs <= _dificuldade.laranja) return Colors.orange;
    return pianoWrong;
  }

  String _textoDesvio(double desvio) {
    final d = _dificuldade;
    final abs = desvio.abs();
    if (abs <= d.verde) return '✓ afinado!';
    if (desvio > d.verde) return '↑ agudo demais (cante mais grave)';
    if (desvio < -d.verde) return '↓ grave demais (cante mais agudo)';
    return '';
  }

  String _statusRegra(double cents) {
    final d = _dificuldade;
    final abs = cents.abs();
    if (abs <= d.verde) return '✓ Afinado';
    if (abs <= d.laranja) return '~ Semitonado';
    return '✗ Desafinado';
  }

  Color _corStatus(double cents) {
    final d = _dificuldade;
    final abs = cents.abs();
    if (abs <= d.verde) return pianoCorrect;
    if (abs <= d.laranja) return Colors.orange;
    return pianoWrong;
  }

  Widget _buildRegra() {
    final d = _dificuldade;
    final escala = d.laranja + 20;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pianoWhite,
        border: Border.all(color: pianoBlack, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📏 Como está o desvio?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: pianoBlack)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: pianoIce,
                borderRadius: BorderRadius.circular(10)),
              child: Text(d.subtitulo,
                  style: const TextStyle(fontSize: 11, color: pianoGray)),
            ),
          ]),
          const SizedBox(height: 12),
          ToggleButtons(
            isSelected: Dificuldade.values.map((e) => e == d).toList(),
            onPressed: (i) =>
                setState(() => _dificuldade = Dificuldade.values[i]),
            constraints: const BoxConstraints(minHeight: 36),
            selectedColor: pianoWhite,
            fillColor: pianoBlack,
            color: pianoBlack,
            borderColor: pianoBlack,
            children: Dificuldade.values
                .map((e) => Text(e.nome, style: const TextStyle(fontSize: 13)))
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _ruleItem(pianoWrong, '> ${d.laranja} cents', 'Desafinado'),
            _ruleItem(Colors.orange, '${d.verde}–${d.laranja}', 'Quase lá'),
            _ruleItem(pianoCorrect, 'até ±${d.verde}', 'Afinado ✓'),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: 18,
            child: LayoutBuilder(builder: (ctx, space) {
              final w = space.maxWidth;
              final wVerde = (d.verde / escala) * w / 2;
              final wLaranja = ((d.laranja - d.verde) / escala) * w / 2;
              final wVermelho = (w / 2) - wVerde - wLaranja;
              return Stack(children: [
                Row(children: [
                  Expanded(child: Container(color: pianoWrong.withOpacity(0.5))),
                  Container(width: wVermelho, color: pianoWrong.withOpacity(0.5)),
                  Container(width: wLaranja, color: Colors.orange.withOpacity(0.5)),
                  Container(width: wVerde, color: pianoCorrect.withOpacity(0.5)),
                  Container(width: wVerde, color: pianoCorrect.withOpacity(0.5)),
                  Container(width: wLaranja, color: Colors.orange.withOpacity(0.5)),
                  Container(width: wVermelho, color: pianoWrong.withOpacity(0.5)),
                  Expanded(child: Container(color: pianoWrong.withOpacity(0.5))),
                ]),
                Center(child: Container(width: 2, color: pianoBlack)),
              ]);
            }),
          ),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('-$escala', style: const TextStyle(fontSize: 10, color: pianoGray)),
            const Text('0', style: TextStyle(fontSize: 10, color: pianoGray)),
            Text('+$escala', style: const TextStyle(fontSize: 10, color: pianoGray)),
          ]),
          const SizedBox(height: 8),
          const Text('↑ cante + grave  ·  ↓ cante + agudo',
              style: TextStyle(fontSize: 12, color: pianoGray)),
        ],
      ),
    );
  }

  static Widget _ruleItem(Color cor, String faixa, String rotulo) {
    return Expanded(
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: cor,
          child: Text(faixa,
              textAlign: TextAlign.center,
              style: const TextStyle(color: pianoWhite, fontSize: 12)),
        ),
        const SizedBox(height: 2),
        Text(rotulo, style: const TextStyle(fontSize: 11, color: pianoBlack)),
      ]),
    );
  }

  Widget _buildListaNotasSequencia() {
    final seq = _gerarSequencia();
    final emAndamento = _fase == FaseSequencia.ouvindo || _fase == FaseSequencia.tocando;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pianoWhite,
        border: Border.all(color: pianoBlack, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📋 Notas da escala',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: pianoBlack)),
            const Spacer(),
            Text('${seq.length} notas',
                style: const TextStyle(fontSize: 12, color: pianoGray)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(seq.length, (i) {
              final n = seq[i];
              final isAtual = emAndamento && i == _indiceNotaAtual;
              final isPassada = emAndamento && i < _indiceNotaAtual;
              final isFutura = emAndamento && i > _indiceNotaAtual;
              Color cor;
              if (isAtual) {
                cor = pianoBlack;
              } else if (isPassada) {
                cor = pianoGray.withOpacity(0.3);
              } else if (isFutura) {
                cor = pianoIce;
              } else {
                cor = pianoWhite;
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: pianoBlack, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${i + 1}.',
                        style: TextStyle(
                            fontSize: 11,
                            color: isAtual ? pianoWhite : pianoGray)),
                    const SizedBox(width: 4),
                    Text(n.nome,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isAtual ? pianoWhite : pianoBlack)),
                    if (_modoVogal == ModoVogal.todas) ...[
                      const SizedBox(width: 4),
                      Text(_vogalDaNota(i),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isAtual ? pianoWhite : pianoBlack)),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownEscalas(bool emProgresso) {
    return DropdownButtonFormField<String>(
      value: _sequenciaSelecionada,
      isExpanded: true,
      decoration: const InputDecoration(
          labelText: 'Exercício / Escala',
          border: OutlineInputBorder(
            borderSide: BorderSide(color: pianoBlack, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: pianoBlack, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: pianoBlack, width: 2),
          )),
      dropdownColor: pianoWhite,
      items: [
        for (final entry in _categorias.entries) ...[
          DropdownMenuItem<String>(
            enabled: false,
            child: Text(entry.key,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: pianoBlack,
                    fontSize: 13)),
          ),
          for (final nome in entry.value.keys)
            DropdownMenuItem<String>(
              value: nome,
              child: Text(nome, style: const TextStyle(fontSize: 14, color: pianoBlack)),
            ),
        ],
      ],
      onChanged: emProgresso
          ? null
          : (v) => setState(() => _sequenciaSelecionada = v!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: pianoWhite,
        cardTheme: CardThemeData(
          color: pianoWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: pianoBlack, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: pianoBlack,
          foregroundColor: pianoWhite,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: pianoBlack,
            foregroundColor: pianoWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: pianoBlack, width: 1),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: pianoBlack, width: 1),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: pianoBlack, width: 2),
          ),
        ),
      ),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: pianoWhite,
          appBar: AppBar(
            backgroundColor: pianoBlack,
            title: const Text('Afinador Vocal', style: TextStyle(color: pianoWhite)),
            bottom: TabBar(
              indicatorColor: pianoWhite,
              labelColor: pianoWhite,
              unselectedLabelColor: pianoGray,
              tabs: const [
                Tab(text: 'Afinador'),
                Tab(text: 'Escala'),
              ],
            ),
          ),
          body: TabBarView(children: [
            _buildAbaAfinador(),
            _buildAbaSequencia(),
          ]),
        ),
      ),
    );
  }

  Widget _buildAbaAfinador() {
    final desvio = _desvioAlvo;
    final cor = _corDesvio(desvio);
    final seta = _textoDesvio(desvio);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRegra(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: pianoWhite,
              border: Border.all(color: pianoBlack, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              const Text('Nota de referência',
                  style: TextStyle(fontSize: 14, color: pianoGray)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _notaSimples,
                    decoration: const InputDecoration(labelText: 'Nota'),
                    items: noteNames
                        .map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(color: pianoBlack))))
                        .toList(),
                    onChanged: (v) {
                      _notaSimples = v!;
                      _atualizarAlvo();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _oitava,
                    decoration: const InputDecoration(labelText: 'Oitava'),
                    items: [
                      for (var o = 0; o <= 8; o++)
                        DropdownMenuItem(value: o, child: Text('$o', style: const TextStyle(color: pianoBlack)))
                    ],
                    onChanged: (v) {
                      _oitava = v!;
                      _atualizarAlvo();
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Text(_notaAlvo,
                  style: const TextStyle(
                      fontSize: 72, fontWeight: FontWeight.bold, color: pianoBlack)),
              Text('${_freqAlvo.toStringAsFixed(2)} Hz',
                  style: const TextStyle(fontSize: 18, color: pianoGray)),
              const SizedBox(height: 16),
              const Text('🗣 Vogal para cantar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: pianoBlack)),
              const SizedBox(height: 8),
              Row(children: [
                for (final v in vogais)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () => setState(() => _vogalAfinador = v),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: _vogalAfinador == v ? pianoBlack : pianoWhite,
                          foregroundColor: _vogalAfinador == v ? pianoWhite : pianoBlack,
                          shape: const CircleBorder(),
                          side: const BorderSide(color: pianoBlack, width: 1),
                        ),
                        child: Text(v,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _tocarNota,
                icon: const Icon(Icons.volume_up),
                label: Text('Tocar vogal "${_vogalAfinador}"'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: pianoBlack,
                  foregroundColor: pianoWhite,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _ouvindo ? _parar : _iniciarOuvir,
            icon: Icon(_ouvindo ? Icons.stop : Icons.mic),
            label: Text(_ouvindo ? 'Parar de ouvir' : 'Começar a cantar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _ouvindo ? pianoWrong : pianoBlack,
              foregroundColor: pianoWhite,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: pianoWhite,
              border: Border.all(color: pianoBlack, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              const Text('Você cantou',
                  style: TextStyle(fontSize: 14, color: pianoGray)),
              const SizedBox(height: 8),
              Text(_notaCantada,
                  style: const TextStyle(
                      fontSize: 64, fontWeight: FontWeight.bold, color: pianoBlack)),
              Text(
                  _freqCantada > 0
                      ? '${_freqCantada.toStringAsFixed(1)} Hz'
                      : '—',
                  style: const TextStyle(fontSize: 18, color: pianoGray)),
              const SizedBox(height: 8),
              Text(
                _freqCantada > 0
                    ? '${desvio.toStringAsFixed(0)} cents · $seta'
                    : 'Cante para ver o resultado',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: cor),
              ),
              const SizedBox(height: 16),
              _buildMedidor(desvio),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildAbaSequencia() {
    final emProgresso =
        _fase == FaseSequencia.contagem ||
        _fase == FaseSequencia.tocando ||
        _fase == FaseSequencia.ouvindo;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: pianoWhite,
              border: Border.all(color: pianoBlack, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              const Text('Escala de notas',
                  style: TextStyle(fontSize: 14, color: pianoGray)),
              const SizedBox(height: 12),
              _buildDropdownEscalas(emProgresso),
              const SizedBox(height: 16),

              const Text('🎼 Tom base (tônica)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: pianoBlack)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _notaRaiz,
                    decoration: const InputDecoration(labelText: 'Nota raiz'),
                    items: noteNames
                        .map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(color: pianoBlack))))
                        .toList(),
                    onChanged: emProgresso
                        ? null
                        : (v) => setState(() => _notaRaiz = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              const Text('🎤 Registro vocal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: pianoBlack)),
              const SizedBox(height: 8),
              Row(children: [
                for (final reg in registrosVocais)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ElevatedButton(
                        onPressed: emProgresso
                            ? null
                            : () => setState(() => _registroVocal = reg),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: _registroVocal == reg ? pianoBlack : pianoWhite,
                          foregroundColor: _registroVocal == reg ? pianoWhite : pianoBlack,
                          side: const BorderSide(color: pianoBlack, width: 1),
                        ),
                        child: Text('Reg. $reg',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 4),
              Text('A escala começa em $_notaRaiz no registro $_registroVocal',
                  style: const TextStyle(fontSize: 11, color: pianoGray)),
              const SizedBox(height: 16),

              const Text('🗣 Vogal para cantar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: pianoBlack)),
              const SizedBox(height: 8),
              ToggleButtons(
                isSelected: [
                  _modoVogal == ModoVogal.fixa,
                  _modoVogal == ModoVogal.todas,
                ],
                onPressed: emProgresso
                    ? null
                    : (i) => setState(() =>
                          _modoVogal = i == 0 ? ModoVogal.fixa : ModoVogal.todas),
                constraints: const BoxConstraints(minHeight: 32),
                selectedColor: pianoWhite,
                fillColor: pianoBlack,
                color: pianoBlack,
                borderColor: pianoBlack,
                children: const [
                  Text('Fixa', style: TextStyle(fontSize: 13)),
                  Text('Todas (A,E,I,O,U)', style: TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              if (_modoVogal == ModoVogal.fixa)
                Row(children: [
                  for (final v in vogais)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: emProgresso
                              ? null
                              : () => setState(() => _vogalSelecionada = v),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: _vogalSelecionada == v ? pianoBlack : pianoWhite,
                            foregroundColor: _vogalSelecionada == v ? pianoWhite : pianoBlack,
                            shape: const CircleBorder(),
                            side: const BorderSide(color: pianoBlack, width: 1),
                          ),
                          child: Text(v,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ])
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: pianoIce,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: pianoBlack, width: 1),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info, color: pianoBlack, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Cada nota será cantada com uma vogal diferente (A, E, I, O, U)',
                          style: TextStyle(fontSize: 12, color: pianoBlack)),
                    ),
                  ]),
                ),
              const SizedBox(height: 16),

              const Text('⚡ Velocidade do exercício',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: pianoBlack)),
              const SizedBox(height: 8),

              Row(children: [
                for (final entry in _presetsBpm.entries)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: emProgresso
                            ? null
                            : () => setState(() => _bpm = entry.value),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: _bpm == entry.value ? pianoBlack : pianoWhite,
                          foregroundColor: _bpm == entry.value ? pianoWhite : pianoBlack,
                          side: const BorderSide(color: pianoBlack, width: 1),
                        ),
                        child: Text(entry.key,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                const Icon(Icons.speed, size: 20, color: pianoBlack),
                const SizedBox(width: 8),
                const Text('BPM', style: TextStyle(color: pianoBlack)),
                Expanded(
                  child: Slider(
                    value: _bpm,
                    min: 40,
                    max: 140,
                    divisions: 20,
                    label: '${_bpm.round()}',
                    activeColor: pianoBlack,
                    inactiveColor: pianoIce,
                    onChanged: emProgresso
                        ? null
                        : (v) => setState(() => _bpm = v),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pianoIce,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: pianoBlack, width: 1),
                  ),
                  child: Text('${_bpm.round()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: pianoBlack,
                          fontSize: 16)),
                ),
              ]),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: emProgresso ? null : _ouvirSequencia,
                icon: const Icon(Icons.headphones),
                label: const Text('🎧 Ouvir escala'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: pianoBlack,
                  foregroundColor: pianoWhite,
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: emProgresso ? _parar : _iniciarSequencia,
                icon: Icon(emProgresso ? Icons.stop : Icons.mic),
                label: Text(emProgresso ? 'Parar' : '🎤 Validar escala'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: emProgresso ? pianoWrong : pianoBlack,
                  foregroundColor: pianoWhite,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          _buildListaNotasSequencia(),
          const SizedBox(height: 16),

          if (_fase != FaseSequencia.parado) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: pianoWhite,
                border: Border.all(color: pianoBlack, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                if (_fase == FaseSequencia.contagem)
                  Column(children: [
                    Text('$_batidaContagem',
                        style: const TextStyle(
                            fontSize: 60, fontWeight: FontWeight.bold, color: pianoBlack)),
                    const Text('Prepare-se...',
                        style: TextStyle(fontSize: 16, color: pianoGray)),
                  ])
                else if (_fase == FaseSequencia.tocando)
                  Column(children: [
                    const Text('Cante agora',
                        style: TextStyle(fontSize: 14, color: pianoGray)),
                    Text(_notaAlvo,
                        style: const TextStyle(
                            fontSize: 72, fontWeight: FontWeight.bold, color: pianoBlack)),
                    Text(
                        'Nota ${_indiceNotaAtual + 1} de ${_sequenciaAtual.length}',
                        style: const TextStyle(
                            fontSize: 16, color: pianoGray)),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: pianoBlack,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          'Cante a vogal "${_vogalDaNota(_indiceNotaAtual)}"',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: pianoWhite)),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                        value: (_indiceNotaAtual + 1) / _sequenciaAtual.length,
                        backgroundColor: pianoIce,
                        valueColor: const AlwaysStoppedAnimation<Color>(pianoBlack)),
                    const SizedBox(height: 12),
                    Text(_notaCantada,
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold, color: pianoBlack)),
                    Text(
                      _freqCantada > 0
                          ? '${_desvioAlvo.toStringAsFixed(0)} cents'
                          : '—',
                      style: TextStyle(
                          fontSize: 18, color: _corDesvio(_desvioAlvo)),
                    ),
                  ])
                else if (_fase == FaseSequencia.ouvindo)
                  Column(children: [
                    const Icon(Icons.headphones, color: pianoBlack, size: 48),
                    const SizedBox(height: 8),
                    const Text('Ouvindo escala...',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: pianoBlack)),
                    Text(
                        'Nota ${_indiceNotaAtual + 1} de ${_sequenciaAtual.length}',
                        style: const TextStyle(
                            fontSize: 16, color: pianoGray)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                        value: (_indiceNotaAtual + 1) / _sequenciaAtual.length,
                        backgroundColor: pianoIce,
                        valueColor: const AlwaysStoppedAnimation<Color>(pianoBlack)),
                    const SizedBox(height: 12),
                    Text(_notaAlvo,
                        style: const TextStyle(
                            fontSize: 56, fontWeight: FontWeight.bold, color: pianoBlack)),
                  ])
                else
                  const Column(children: [
                    Icon(Icons.check_circle, color: pianoCorrect, size: 48),
                    SizedBox(height: 8),
                    Text('Escala concluída!',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: pianoBlack)),
                  ]),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          if (_gravando || _audioUrl != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: pianoWhite,
                border: Border.all(color: pianoBlack, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('🎙 Gravação',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold, color: pianoBlack)),
                  const SizedBox(height: 12),
                  if (_gravando)
                    Row(children: [
                      Icon(Icons.fiber_manual_record,
                          color: pianoWrong, size: 20),
                      const SizedBox(width: 8),
                      const Text('Gravando sua voz + notas...',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: pianoWrong)),
                    ])
                  else if (_audioUrl != null)
                    Column(children: [
                      const Text('Gravação finalizada! (voz + notas)',
                          style: TextStyle(fontSize: 15, color: pianoBlack)),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _ouvirGravacao,
                        icon: const Icon(Icons.play_circle),
                        label: const Text('🎧 Ouvir gravação'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: pianoBlack,
                          foregroundColor: pianoWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _baixarGravacao,
                        icon: const Icon(Icons.download),
                        label: Text('⬇️ Baixar áudio (.$_extensaoAudio)'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: pianoCorrect,
                          foregroundColor: pianoWhite,
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          const SizedBox(height: 16),

          if (_resultados.isNotEmpty) _buildResultados(),
        ],
      ),
    );
  }

  Widget _buildResultados() {
    final certas = _resultados.where((r) => r.notaCerta).length;
    final afinadas = _resultados.where((r) => r.afinado).length;
    final total = _resultados.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pianoWhite,
        border: Border.all(color: pianoBlack, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Resultado',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: pianoBlack)),
        const SizedBox(height: 8),
        Text('Notas certas: $certas/$total', style: const TextStyle(fontSize: 15, color: pianoBlack)),
        Text('Afinadas: $afinadas/$total', style: const TextStyle(fontSize: 15, color: pianoBlack)),
        const SizedBox(height: 12),
        ..._resultados.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          final cor = !r.cantou
              ? pianoGray
              : (r.notaCerta && r.afinado
                  ? pianoCorrect
                  : (r.notaCerta ? Colors.orange : pianoWrong));
          final icone = !r.cantou
              ? '·'
              : (r.notaCerta && r.afinado
                  ? '✓'
                  : (r.notaCerta ? '~' : '✗'));
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(
                  width: 40,
                  child: Text('${i + 1}.',
                      style: const TextStyle(color: pianoGray))),
              Expanded(
                  child: Text(r.alvo,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: pianoBlack))),
              Expanded(
                  child: Text(r.cantada,
                      style: const TextStyle(color: pianoGray))),
              if (r.cantou)
                Expanded(
                    child: Text(
                      r.notaCerta
                          ? _statusRegra(r.cents.toDouble())
                          : 'Nota errada',
                      style: TextStyle(
                          color: r.notaCerta ? _corStatus(r.cents.toDouble()) : pianoWrong,
                          fontWeight: FontWeight.bold),
                    )),
              Icon(Icons.circle, color: cor, size: 14),
              const SizedBox(width: 4),
              Text(icone,
                  style:
                      TextStyle(color: cor, fontWeight: FontWeight.bold)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildMedidor(double desvio) {
    final escala = _dificuldade.laranja + 20;
    final pos = (desvio / escala).clamp(-1.0, 1.0);
    return Column(children: [
      SizedBox(
        height: 30,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(height: 6, color: pianoIce),
            Container(
              width: 60,
              height: 10,
              decoration: BoxDecoration(
                  color: pianoCorrect, borderRadius: BorderRadius.circular(5)),
            ),
            Align(
              alignment: Alignment(pos, 0),
              child: Container(
                width: 5,
                height: 26,
                decoration: BoxDecoration(
                    color: pianoBlack,
                    borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('-$escala', style: const TextStyle(fontSize: 11, color: pianoGray)),
        const Text('0', style: TextStyle(fontSize: 11, color: pianoGray)),
        Text('+$escala', style: const TextStyle(fontSize: 11, color: pianoGray)),
      ]),
    ]);
  }
}
