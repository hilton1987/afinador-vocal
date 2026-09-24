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

const Map<String, List<double>> formantes = {
  'A': [730, 1090, 2440],
  'E': [530, 1840, 2480],
  'I': [270, 2290, 3010],
  'O': [570, 840, 2410],
  'U': [300, 870, 2240],
};

// ====== PALETA MODERNA 3D ======
const Color bgDeep = Color(0xFF08080F);   // topo
const Color bgMid = Color(0xFF131320);    // meio
const Color bgGlow = Color(0xFF1E1633);   // brilho violeta sutil
const Color gold = Color(0xFFD4AF37);
const Color goldBright = Color(0xFFFFD700);
const Color goldSoft = Color(0xFF9C7B1E);
const Color goldShadow = Color(0x55B8860B);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFFA5A5B5);
const Color textMuted = Color(0xFF6E6E80);
const Color cardBg = Color(0x14FFFFFF);
const Color cardBorder = Color(0x1FFFFFFF);
const Color danger = Color(0xFFFF4757);
const Color warning = Color(0xFFFFA502);
const Color success = Color(0xFF22C55E);

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

// ====== CARD 3D COM PROFUNDIDADE ======
class _LuxCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _LuxCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x20FFFFFF), Color(0x08FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: gold.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ====== TÍTULO ======
class _LuxTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  const _LuxTitle(this.text, {this.fontSize = 14, this.color = textSecondary});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ====== BOTÃO 3D COM BRILHO NO HOVER ======
class _LuxButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? foreground;
  final IconData? icon;
  final bool isGold;
  final bool isDanger;

  const _LuxButton({
    required this.label,
    required this.onPressed,
    this.background,
    this.foreground,
    this.icon,
    this.isGold = false,
    this.isDanger = false,
  });

  @override
  State<_LuxButton> createState() => _LuxButtonState();
}

class _LuxButtonState extends State<_LuxButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    final gradient = widget.isGold
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [goldBright, gold, goldSoft],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (widget.isDanger ? danger : (widget.background ?? const Color(0x1AFFFFFF)))
                  .withOpacity(enabled ? 1 : 0.4),
              (widget.isDanger ? danger.withOpacity(0.85) : (widget.background ?? const Color(0x0DFFFFFF)))
                  .withOpacity(enabled ? 1 : 0.3),
            ],
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: widget.isGold
              ? null
              : Border.all(
                  color: enabled
                      ? (widget.isDanger ? danger : gold.withOpacity(0.5))
                      : textMuted.withOpacity(0.3),
                  width: 1.2),
          boxShadow: [
            BoxShadow(
              color: widget.isGold ? goldShadow : Colors.black.withOpacity(0.45),
              blurRadius: _hover ? 24 : 12,
              offset: const Offset(0, 6),
            ),
            if (_hover && enabled)
              BoxShadow(
                color: (widget.isGold ? goldBright : gold).withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, -2),
              ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: _hover && enabled && !widget.isGold
                      ? goldBright
                      : (widget.foreground ?? textPrimary),
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: _hover && enabled && !widget.isGold
                      ? goldBright
                      : (widget.foreground ?? textPrimary),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AfinadorApp extends StatefulWidget {
  const AfinadorApp({super.key});
  @override
  State<AfinadorApp> createState() => _AfinadorAppState();
}

class _AfinadorAppState extends State<AfinadorApp> {
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

  web.AudioContext? _audioCtx;
  web.MediaStream? _stream;
  web.AnalyserNode? _analyser;
  Float32List _dataArray = Float32List(2048);
  Timer? _timerDeteccao;
  Timer? _timerSequencia;

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
    masterGain.gain.setValueAtTime(0.25, now + dur - 0.1);
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
    if (abs <= _dificuldade.verde) return goldBright;
    if (abs <= _dificuldade.laranja) return warning;
    return danger;
  }

  String _textoDesvio(double desvio) {
    final d = _dificuldade;
    final abs = desvio.abs();
    if (abs <= d.verde) return '✨ afinado!';
    if (desvio > d.verde) return '↑ agudo demais';
    if (desvio < -d.verde) return '↓ grave demais';
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
    if (abs <= d.verde) return goldBright;
    if (abs <= d.laranja) return warning;
    return danger;
  }

  Widget _buildRegra() {
    final d = _dificuldade;
    final escala = d.laranja + 20;
    return _LuxCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _LuxTitle('📏  Regra de afinação', fontSize: 12),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gold.withOpacity(0.2), goldSoft.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gold.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: gold.withOpacity(0.1), blurRadius: 8)],
              ),
              child: Text(d.subtitulo,
                  style: const TextStyle(
                      fontSize: 11, color: gold, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            for (var i = 0; i < Dificuldade.values.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _dificuldade = Dificuldade.values[i]),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: d == Dificuldade.values[i]
                              ? const LinearGradient(colors: [goldBright, gold, goldSoft])
                              : null,
                          color: d == Dificuldade.values[i]
                              ? null
                              : const Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: d == Dificuldade.values[i] ? goldBright : cardBorder,
                          ),
                          boxShadow: d == Dificuldade.values[i]
                              ? [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4))]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          Dificuldade.values[i].nome,
                          style: TextStyle(
                            fontSize: 12,
                            color: d == Dificuldade.values[i] ? bgDeep : textSecondary,
                            fontWeight: d == Dificuldade.values[i] ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            _ruleItem(danger, '> ${d.laranja} cents', 'Desafinado'),
            _ruleItem(warning, '${d.verde}–${d.laranja}', 'Quase lá'),
            _ruleItem(goldBright, 'até ±${d.verde}', 'Afinado ✨'),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 18,
            child: LayoutBuilder(builder: (ctx, space) {
              final w = space.maxWidth;
              final wVerde = (d.verde / escala) * w / 2;
              final wLaranja = ((d.laranja - d.verde) / escala) * w / 2;
              final wVermelho = (w / 2) - wVerde - wLaranja;
              return Stack(children: [
                Row(children: [
                  Expanded(child: Container(color: danger.withOpacity(0.3))),
                  Container(width: wVermelho, color: danger.withOpacity(0.3)),
                  Container(width: wLaranja, color: warning.withOpacity(0.3)),
                  Container(width: wVerde, color: goldBright.withOpacity(0.3)),
                  Container(width: wVerde, color: goldBright.withOpacity(0.3)),
                  Container(width: wLaranja, color: warning.withOpacity(0.3)),
                  Container(width: wVermelho, color: danger.withOpacity(0.3)),
                  Expanded(child: Container(color: danger.withOpacity(0.3))),
                ]),
                Center(child: Container(width: 2, color: gold)),
              ]);
            }),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('-$escala', style: const TextStyle(fontSize: 10, color: textMuted)),
            const Text('0', style: TextStyle(fontSize: 10, color: textMuted)),
            Text('+$escala', style: const TextStyle(fontSize: 10, color: textMuted)),
          ]),
        ],
      ),
    );
  }

  static Widget _ruleItem(Color cor, String faixa, String rotulo) {
    return Expanded(
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: cor.withOpacity(0.25),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            border: Border.all(color: cor.withOpacity(0.5)),
          ),
          child: Text(faixa,
              textAlign: TextAlign.center,
              style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 4),
        Text(rotulo, style: const TextStyle(fontSize: 11, color: textSecondary)),
      ]),
    );
  }

  Widget _buildListaNotasSequencia() {
    final seq = _gerarSequencia();
    final emAndamento = _fase == FaseSequencia.ouvindo || _fase == FaseSequencia.tocando;
    return _LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _LuxTitle('📋  Notas da escala', fontSize: 12),
            const Spacer(),
            Text('${seq.length} notas',
                style: const TextStyle(fontSize: 12, color: textMuted)),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(seq.length, (i) {
              final n = seq[i];
              final isAtual = emAndamento && i == _indiceNotaAtual;
              final isPassada = emAndamento && i < _indiceNotaAtual;
              final isFutura = emAndamento && i > _indiceNotaAtual;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isAtual
                      ? const LinearGradient(colors: [goldBright, gold, goldSoft])
                      : null,
                  color: isAtual
                      ? null
                      : (isPassada
                          ? textMuted.withOpacity(0.15)
                          : (isFutura ? const Color(0x0DFFFFFF) : const Color(0x14FFFFFF))),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isAtual
                        ? goldBright
                        : (isPassada ? textMuted.withOpacity(0.3) : cardBorder),
                  ),
                  boxShadow: isAtual
                      ? [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${i + 1}.',
                        style: TextStyle(
                            fontSize: 10,
                            color: isAtual ? bgDeep : textMuted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text(n.nome,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isAtual ? bgDeep : textPrimary)),
                    if (_modoVogal == ModoVogal.todas) ...[
                      const SizedBox(width: 4),
                      Text(_vogalDaNota(i),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAtual ? bgDeep : gold)),
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
      dropdownColor: bgMid,
      style: const TextStyle(color: textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Exercício / Escala',
        labelStyle: const TextStyle(color: textSecondary, fontSize: 12, letterSpacing: 1),
        filled: true,
        fillColor: const Color(0x0DFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: gold.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
      ),
      items: [
        for (final entry in _categorias.entries) ...[
          DropdownMenuItem<String>(
            enabled: false,
            child: Text(entry.key,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: gold,
                    fontSize: 13)),
          ),
          for (final nome in entry.value.keys)
            DropdownMenuItem<String>(
              value: nome,
              child: Text(nome, style: const TextStyle(fontSize: 14, color: textPrimary)),
            ),
        ],
      ],
      onChanged: emProgresso
          ? null
          : (v) => setState(() => _sequenciaSelecionada = v!),
    );
  }

  Widget _buildDropdownSimples<T>({
    required T value,
    required List<T> items,
    required String Function(T) itemText,
    required ValueChanged<T?> onChanged,
    String? label,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      dropdownColor: bgMid,
      style: const TextStyle(color: textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 12, letterSpacing: 1),
        filled: true,
        fillColor: const Color(0x0DFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: gold.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
      ),
      items: items
          .map((i) => DropdownMenuItem<T>(
                value: i,
                child: Text(itemText(i), style: const TextStyle(color: textPrimary)),
              ))
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        primaryColor: gold,
        scaffoldBackgroundColor: bgDeep,
        canvasColor: bgDeep,
        cardColor: bgMid,
        dialogBackgroundColor: bgMid,
        indicatorColor: gold,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: goldSoft,
          surface: bgMid,
          background: bgDeep,
          onPrimary: bgDeep,
          onSecondary: textPrimary,
          onSurface: textPrimary,
          onBackground: textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: const Color(0x0DFFFFFF),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: gold, width: 1.5),
          ),
        ),
      ),
      home: DefaultTabController(
        length: 2,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgDeep, bgMid, bgGlow, bgMid, bgDeep],
              stops: [0.0, 0.3, 0.55, 0.8, 1.0],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.graphic_eq, color: gold, size: 28),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [goldBright, gold, goldSoft],
                    ).createShader(bounds),
                    child: const Text(
                      'Afinador Vocal',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 3.0,
                      ),
                    ),
                  ),
                ],
              ),
              bottom: TabBar(
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: goldBright, width: 2),
                  insets: EdgeInsets.symmetric(horizontal: 40),
                ),
                labelColor: goldBright,
                unselectedLabelColor: textMuted,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2.0,
                ),
                tabs: const [
                  Tab(text: 'AFINADOR'),
                  Tab(text: 'ESCALA'),
                ],
              ),
            ),
            body: const TabBarView(children: [
              _AbaAfinadorWrapper(),
              _AbaSequenciaWrapper(),
            ]),
          ),
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
          _LuxCard(
            child: Column(children: [
              const _LuxTitle('Nota de referência'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _buildDropdownSimples<String>(
                    value: _notaSimples,
                    items: noteNames,
                    itemText: (n) => n,
                    label: 'Nota',
                    onChanged: (v) {
                      _notaSimples = v!;
                      _atualizarAlvo();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownSimples<int>(
                    value: _oitava,
                    items: List.generate(9, (i) => i),
                    itemText: (o) => '$o',
                    label: 'Oitava',
                    onChanged: (v) {
                      _oitava = v!;
                      _atualizarAlvo();
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [goldBright, gold, goldSoft],
                ).createShader(bounds),
                child: Text(_notaAlvo,
                    style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w200,
                        color: textPrimary,
                        letterSpacing: 4,
                        height: 1.0)),
              ),
              Text('${_freqAlvo.toStringAsFixed(2)} Hz',
                  style: const TextStyle(fontSize: 16, color: textMuted, letterSpacing: 1)),
              const SizedBox(height: 24),
              const Divider(color: cardBorder, height: 1),
              const SizedBox(height: 20),
              const _LuxTitle('🗣  Vogal para cantar'),
              const SizedBox(height: 12),
              Row(children: [
                for (final v in vogais)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _vogalAfinador = v),
                          customBorder: const CircleBorder(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _vogalAfinador == v
                                  ? const LinearGradient(colors: [goldBright, gold, goldSoft])
                                  : null,
                              color: _vogalAfinador == v ? null : const Color(0x0DFFFFFF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _vogalAfinador == v ? goldBright : cardBorder,
                              ),
                              boxShadow: _vogalAfinador == v
                                  ? [BoxShadow(color: gold.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(v,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _vogalAfinador == v ? bgDeep : textPrimary)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 20),
              _LuxButton(
                label: 'Tocar vogal "${_vogalAfinador}"',
                icon: Icons.volume_up,
                onPressed: _tocarNota,
                isGold: true,
                foreground: bgDeep,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _LuxButton(
            label: _ouvindo ? 'Parar de ouvir' : 'Começar a cantar',
            icon: _ouvindo ? Icons.stop : Icons.mic,
            onPressed: _ouvindo ? _parar : _iniciarOuvir,
            background: _ouvindo ? danger : null,
            isGold: !_ouvindo,
            isDanger: _ouvindo,
            foreground: _ouvindo ? textPrimary : bgDeep,
          ),
          const SizedBox(height: 16),
          _LuxCard(
            child: Column(children: [
              const _LuxTitle('Você cantou'),
              const SizedBox(height: 12),
              Text(_notaCantada,
                  style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w200,
                      color: textPrimary,
                      letterSpacing: 3)),
              Text(
                  _freqCantada > 0
                      ? '${_freqCantada.toStringAsFixed(1)} Hz'
                      : '—',
                  style: const TextStyle(fontSize: 16, color: textMuted, letterSpacing: 1)),
              const SizedBox(height: 12),
              Text(
                _freqCantada > 0
                    ? '${desvio.toStringAsFixed(0)} cents · $seta'
                    : 'Cante para ver o resultado',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: cor, letterSpacing: 0.5),
              ),
              const SizedBox(height: 20),
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
          _LuxCard(
            child: Column(children: [
              const _LuxTitle('Escala de notas'),
              const SizedBox(height: 16),
              _buildDropdownEscalas(emProgresso),
              const SizedBox(height: 20),

              const _LuxTitle('🎼  Tom base (tônica)'),
              const SizedBox(height: 12),
              _buildDropdownSimples<String>(
                value: _notaRaiz,
                items: noteNames,
                itemText: (n) => n,
                label: 'Nota raiz',
                enabled: !emProgresso,
                onChanged: (v) => setState(() => _notaRaiz = v!),
              ),
              const SizedBox(height: 20),

              const _LuxTitle('🎤  Registro vocal'),
              const SizedBox(height: 12),
              Row(children: [
                for (final reg in registrosVocais)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: emProgresso
                              ? null
                              : () => setState(() => _registroVocal = reg),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: _registroVocal == reg
                                  ? const LinearGradient(colors: [goldBright, gold, goldSoft])
                                  : null,
                              color: _registroVocal == reg ? null : const Color(0x0DFFFFFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _registroVocal == reg ? goldBright : cardBorder,
                              ),
                              boxShadow: _registroVocal == reg
                                  ? [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text('Reg. $reg',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _registroVocal == reg ? bgDeep : textSecondary)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 6),
              Text('A escala começa em $_notaRaiz no registro $_registroVocal',
                  style: const TextStyle(fontSize: 11, color: textMuted)),
              const SizedBox(height: 20),

              const _LuxTitle('🗣  Vogal para cantar'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: emProgresso ? null : () => setState(() => _modoVogal = ModoVogal.fixa),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: _modoVogal == ModoVogal.fixa
                                ? const LinearGradient(colors: [goldBright, gold, goldSoft])
                                : null,
                            color: _modoVogal == ModoVogal.fixa ? null : const Color(0x0DFFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _modoVogal == ModoVogal.fixa ? goldBright : cardBorder,
                            ),
                            boxShadow: _modoVogal == ModoVogal.fixa
                                ? [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text('Fixa',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _modoVogal == ModoVogal.fixa ? bgDeep : textSecondary)),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: emProgresso ? null : () => setState(() => _modoVogal = ModoVogal.todas),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: _modoVogal == ModoVogal.todas
                                ? const LinearGradient(colors: [goldBright, gold, goldSoft])
                                : null,
                            color: _modoVogal == ModoVogal.todas ? null : const Color(0x0DFFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _modoVogal == ModoVogal.todas ? goldBright : cardBorder,
                            ),
                            boxShadow: _modoVogal == ModoVogal.todas
                                ? [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text('Todas (A,E,I,O,U)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _modoVogal == ModoVogal.todas ? bgDeep : textSecondary)),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (_modoVogal == ModoVogal.fixa)
                Row(children: [
                  for (final v in vogais)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: emProgresso
                                ? null
                                : () => setState(() => _vogalSelecionada = v),
                            customBorder: const CircleBorder(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: _vogalSelecionada == v
                                    ? const LinearGradient(colors: [goldBright, gold, goldSoft])
                                    : null,
                                color: _vogalSelecionada == v ? null : const Color(0x0DFFFFFF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _vogalSelecionada == v ? goldBright : cardBorder,
                                ),
                                boxShadow: _vogalSelecionada == v
                                    ? [BoxShadow(color: gold.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4))]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(v,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _vogalSelecionada == v ? bgDeep : textPrimary)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ])
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: gold.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: gold, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                          'Cada nota será cantada com uma vogal diferente (A, E, I, O, U)',
                          style: TextStyle(fontSize: 12, color: textSecondary)),
                    ),
                  ]),
                ),
              const SizedBox(height: 20),

              const _LuxTitle('⚡  Velocidade do exercício'),
              const SizedBox(height: 12),

              Row(children: [
                for (final entry in _presetsBpm.entries)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: emProgresso
                              ? null
                              : () => setState(() => _bpm = entry.value),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: _bpm == entry.value
                                  ? const LinearGradient(colors: [goldBright, gold, goldSoft])
                                  : null,
                              color: _bpm == entry.value ? null : const Color(0x0DFFFFFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _bpm == entry.value ? goldBright : cardBorder,
                              ),
                              boxShadow: _bpm == entry.value
                                  ? [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(entry.key,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _bpm == entry.value ? bgDeep : textSecondary)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),

              Row(children: [
                const Icon(Icons.speed, size: 20, color: gold),
                const SizedBox(width: 8),
                const Text('BPM', style: TextStyle(color: textSecondary, letterSpacing: 1.5, fontSize: 12)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: goldBright,
                      inactiveTrackColor: textMuted.withOpacity(0.3),
                      thumbColor: goldBright,
                      overlayColor: gold.withOpacity(0.1),
                    ),
                    child: Slider(
                      value: _bpm,
                      min: 40,
                      max: 140,
                      divisions: 20,
                      label: '${_bpm.round()}',
                      onChanged: emProgresso
                          ? null
                          : (v) => setState(() => _bpm = v),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)]),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: gold.withOpacity(0.4)),
                    boxShadow: [BoxShadow(color: gold.withOpacity(0.1), blurRadius: 8)],
                  ),
                  child: Text('${_bpm.round()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: gold,
                          fontSize: 16)),
                ),
              ]),
              const SizedBox(height: 20),

              _LuxButton(
                label: '🎧  Ouvir escala',
                icon: Icons.headphones,
                onPressed: emProgresso ? null : _ouvirSequencia,
                foreground: textPrimary,
              ),
              const SizedBox(height: 12),

              _LuxButton(
                label: emProgresso ? 'Parar' : '🎤  Validar escala',
                icon: emProgresso ? Icons.stop : Icons.mic,
                onPressed: emProgresso ? _parar : _iniciarSequencia,
                background: emProgresso ? danger : null,
                isGold: !emProgresso,
                isDanger: emProgresso,
                foreground: emProgresso ? textPrimary : bgDeep,
              ),
            ]),
          ),
          const SizedBox(height: 16),

          _buildListaNotasSequencia(),
          const SizedBox(height: 16),

          if (_fase != FaseSequencia.parado) ...[
            _LuxCard(
              child: Column(children: [
                if (_fase == FaseSequencia.contagem)
                  Column(children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [goldBright, gold],
                      ).createShader(bounds),
                      child: Text('$_batidaContagem',
                          style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w200,
                              color: textPrimary,
                              letterSpacing: 4)),
                    ),
                    const Text('Prepare-se...',
                        style: TextStyle(fontSize: 14, color: textMuted, letterSpacing: 1.5)),
                  ])
                else if (_fase == FaseSequencia.tocando)
                  Column(children: [
                    const _LuxTitle('Cante agora'),
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [goldBright, gold, goldSoft],
                      ).createShader(bounds),
                      child: Text(_notaAlvo,
                          style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w200,
                              color: textPrimary,
                              letterSpacing: 4)),
                    ),
                    Text(
                        'Nota ${_indiceNotaAtual + 1} de ${_sequenciaAtual.length}',
                        style: const TextStyle(
                            fontSize: 14, color: textMuted, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [goldBright, gold, goldSoft]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: gold.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                          'Cante a vogal "${_vogalDaNota(_indiceNotaAtual)}"',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: bgDeep)),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                          value: (_indiceNotaAtual + 1) / _sequenciaAtual.length,
                          backgroundColor: textMuted.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(goldBright),
                          minHeight: 6),
                    ),
                    const SizedBox(height: 16),
                    Text(_notaCantada,
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w200,
                            color: textPrimary,
                            letterSpacing: 2)),
                    Text(
                      _freqCantada > 0
                          ? '${_desvioAlvo.toStringAsFixed(0)} cents'
                          : '—',
                      style: TextStyle(
                          fontSize: 16, color: _corDesvio(_desvioAlvo), letterSpacing: 1),
                    ),
                  ])
                else if (_fase == FaseSequencia.ouvindo)
                  Column(children: [
                    const Icon(Icons.headphones, color: gold, size: 48),
                    const SizedBox(height: 12),
                    const Text('Ouvindo escala...',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                            letterSpacing: 1.5)),
                    Text(
                        'Nota ${_indiceNotaAtual + 1} de ${_sequenciaAtual.length}',
                        style: const TextStyle(
                            fontSize: 14, color: textMuted, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                          value: (_indiceNotaAtual + 1) / _sequenciaAtual.length,
                          backgroundColor: textMuted.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(gold),
                          minHeight: 6),
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [goldBright, gold],
                      ).createShader(bounds),
                      child: Text(_notaAlvo,
                          style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w200,
                              color: textPrimary,
                              letterSpacing: 3)),
                    ),
                  ])
                else
                  Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [goldBright, gold, goldSoft]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: gold.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.check, color: bgDeep, size: 40),
                    ),
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [gold, goldBright],
                      ).createShader(bounds),
                      child: const Text('Escala concluída!',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              letterSpacing: 1.5)),
                    ),
                  ]),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          if (_gravando || _audioUrl != null)
            _LuxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LuxTitle('🎙  Gravação'),
                  const SizedBox(height: 16),
                  if (_gravando)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: danger.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.fiber_manual_record, color: danger, size: 18),
                        const SizedBox(width: 10),
                        const Text('Gravando sua voz + notas...',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: danger)),
                      ]),
                    )
                  else if (_audioUrl != null)
                    Column(children: [
                      const Text('Gravação finalizada! (voz + notas)',
                          style: TextStyle(fontSize: 14, color: textSecondary)),
                      const SizedBox(height: 12),
                      _LuxButton(
                        label: '🎧  Ouvir gravação',
                        icon: Icons.play_circle,
                        onPressed: _ouvirGravacao,
                        foreground: textPrimary,
                      ),
                      const SizedBox(height: 10),
                      _LuxButton(
                        label: '⬇️  Baixar áudio (.$_extensaoAudio)',
                        icon: Icons.download,
                        onPressed: _baixarGravacao,
                        isGold: true,
                        foreground: bgDeep,
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
    return _LuxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _LuxTitle('Resultado'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x1AFFFFFF), Color(0x08FFFFFF)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(children: [
                Text('$certas/$total',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: textPrimary)),
                const SizedBox(height: 4),
                const Text('Notas certas', style: TextStyle(fontSize: 11, color: textMuted, letterSpacing: 1)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gold.withOpacity(0.3), goldSoft.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gold.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(color: gold.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(children: [
                Text('$afinadas/$total',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: gold)),
                const SizedBox(height: 4),
                const Text('Afinadas ✨', style: TextStyle(fontSize: 11, color: gold, letterSpacing: 1)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        const Divider(color: cardBorder),
        const SizedBox(height: 8),
        ..._resultados.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          final cor = !r.cantou
              ? textMuted
              : (r.notaCerta && r.afinado
                  ? goldBright
                  : (r.notaCerta ? warning : danger));
          final icone = !r.cantou
              ? '·'
              : (r.notaCerta && r.afinado
                  ? '✓'
                  : (r.notaCerta ? '~' : '✗'));
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              SizedBox(
                  width: 32,
                  child: Text('${i + 1}.',
                      style: const TextStyle(color: textMuted, fontSize: 12))),
              Expanded(
                  child: Text(r.alvo,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: textPrimary))),
              Expanded(
                  child: Text(r.cantada,
                      style: const TextStyle(color: textMuted))),
              if (r.cantou)
                Expanded(
                    child: Text(
                      r.notaCerta
                          ? _statusRegra(r.cents.toDouble())
                          : 'Nota errada',
                      style: TextStyle(
                          color: r.notaCerta ? _corStatus(r.cents.toDouble()) : danger,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    )),
              Icon(Icons.circle, color: cor, size: 12),
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
    final afinado = desvio.abs() <= _dificuldade.verde;
    return Column(children: [
      SizedBox(
        height: 36,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: textMuted.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: 70,
              height: 12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [goldBright.withOpacity(0.4), gold.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: goldBright.withOpacity(afinado ? 0.5 : 0.2),
                    blurRadius: afinado ? 16 : 8,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment(pos, 0),
              child: Container(
                width: 6,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [goldBright, gold, goldSoft],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('-$escala', style: const TextStyle(fontSize: 10, color: textMuted)),
        const Text('0', style: TextStyle(fontSize: 10, color: textMuted)),
        Text('+$escala', style: const TextStyle(fontSize: 10, color: textMuted)),
      ]),
    ]);
  }
}

// ====== WRAPPERS PARA AS ABAS ======
class _AbaAfinadorWrapper extends StatefulWidget {
  const _AbaAfinadorWrapper();
  @override
  State<_AbaAfinadorWrapper> createState() => _AbaAfinadorWrapperState();
}

class _AbaAfinadorWrapperState extends State<_AbaAfinadorWrapper> {
  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AfinadorAppState>()!;
    return state._buildAbaAfinador();
  }
}

class _AbaSequenciaWrapper extends StatefulWidget {
  const _AbaSequenciaWrapper();
  @override
  State<_AbaSequenciaWrapper> createState() => _AbaSequenciaWrapperState();
}

class _AbaSequenciaWrapperState extends State<_AbaSequenciaWrapper> {
  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AfinadorAppState>()!;
    return state._buildAbaSequencia();
  }
}
