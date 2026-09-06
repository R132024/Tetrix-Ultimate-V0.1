/// Sistema de internacionalización ligero, sin generación de código.
///
/// Uso:
///   1. Envuelve la app con [LocaleScope] (ya hecho en main.dart).
///   2. En cualquier widget: `context.t('play')` o `tr(context, 'play')`.
///   3. Cambia idioma: `LocaleController.instance.setLocale('en')`.
///
/// Idiomas soportados: es, en, pt, zh, ru.
library;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controlador global del idioma. Persiste la elección con shared_preferences.
class LocaleController {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const _prefsKey = 'app_language_code';
  static const supported = <String>['es', 'en', 'pt', 'zh', 'ru'];

  /// Notifier reactivo: los widgets que escuchan se reconstruyen al cambiar.
  final ValueNotifier<String> localeNotifier = ValueNotifier<String>('es');

  String get code => localeNotifier.value;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && supported.contains(saved)) {
        localeNotifier.value = saved;
      }
    } catch (_) {
      // Si falla, se queda en español por defecto.
    }
  }

  Future<void> setLocale(String codeNew) async {
    if (!supported.contains(codeNew)) return;
    localeNotifier.value = codeNew;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, codeNew);
    } catch (_) {}
  }

  /// Nombre legible del idioma (para mostrar en el selector).
  static String displayName(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      case 'zh':
        return '中文';
      case 'ru':
        return 'Русский';
      default:
        return code;
    }
  }

  /// Bandera emoji para el selector.
  static String flag(String code) {
    switch (code) {
      case 'es':
        return '🇪🇸';
      case 'en':
        return '🇬🇧';
      case 'pt':
        return '🇧🇷';
      case 'zh':
        return '🇨🇳';
      case 'ru':
        return '🇷🇺';
      default:
        return '🏳️';
    }
  }
}

/// Widget que reconstruye su subárbol cuando cambia el idioma.
class LocaleScope extends StatelessWidget {
  const LocaleScope({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleController.instance.localeNotifier,
      builder: (context, _, _) => builder(context),
    );
  }
}

/// Traduce una clave al idioma activo. Si falta, cae a español y luego a la clave.
String tr(BuildContext context, String key, {Map<String, String>? params}) {
  final code = LocaleController.instance.code;
  String value = (_strings[code]?[key]) ?? (_strings['es']?[key]) ?? key;
  if (params != null) {
    params.forEach((k, v) => value = value.replaceAll('{$k}', v));
  }
  return value;
}

extension I18nContext on BuildContext {
  String t(String key, {Map<String, String>? params}) =>
      tr(this, key, params: params);
}

/// Tabla de traducciones. Clave -> { idioma -> texto }.
/// Para añadir un idioma o clave, simplemente agrégalo aquí.
const Map<String, Map<String, String>> _strings = {
  'es': {
    'app_subtitle': 'PUZZLE GAME',
    'play': 'JUGAR',
    'theme_shop': 'TIENDA DE TEMAS',
    'daily_missions': 'MISIONES DIARIAS',
    'scoreboard': 'TABLA DE PUNTUACIONES',
    'no_scores': 'Aún no hay puntuaciones',
    'col_name': 'Nombre',
    'col_mode': 'Tipo de juego',
    'col_level': 'Nivel',
    'col_score': 'Puntuación',
    'mode_classic': 'CLÁSICO',
    'mode_arena': 'ARENA',
    'mode_power': 'PODERES',
    'mode_multi': 'MULTI',
    'mode_online': 'ONLINE',
    'mode_settings': 'AJUSTES',
    'title_classic': 'MODO CLÁSICO',
    'title_arena': 'MODO ARENA',
    'title_power': 'CON PODERES',
    'title_multi': 'MULTIJUGADOR',
    'title_online': 'ONLINE 1v1',
    'title_settings': 'CONFIGURACIÓN',
    'desc_classic': 'El rompecabezas original. Limpia líneas sin presión de tiempo.',
    'desc_arena': '¡Sobrevive a la física de arena! Conecta colores tocando bloques que caen como polvo.',
    'desc_power': 'Usa habilidades especiales como Láser y Bomba para destruir bloques.',
    'desc_multi': 'Desafía a tus amigos en partidas locales y demuestra quién manda.',
    'desc_online': 'Reta a cualquiera por internet en un duelo 1v1 en tiempo real.',
    'desc_settings': 'Ajusta volumen, idioma y otras preferencias.',
    'music': 'MÚSICA',
    'sfx': 'EFECTOS',
    'language': 'IDIOMA',
    'initial_level': 'NIVEL INICIAL',
    'back_home': 'VOLVER AL INICIO',
    'music_mode_on': 'MODO MÚSICA ON',
    'music_mode_off': 'MODO MÚSICA OFF',
    'music_mode_title': '¡MODO MÚSICA ACTIVADO!',
    'music_mode_body': 'Disfruta tu propia música de forma envolvente. ¡El fondo del juego reaccionará y vibrará dinámicamente al ritmo de tus canciones favoritas!',
    'got_it': '¡ENTENDIDO!',
    'best': 'MEJOR',
    'score': 'PUNTOS',
    'lvl': 'NIVEL',
    'lines': 'LÍNEAS',
    'coins': 'MONEDAS',
    'game_over': 'FIN DEL JUEGO',
    'paused': 'EN PAUSA',
    'resume': 'REANUDAR',
    'restart': 'REINICIAR',
    'home': 'INICIO',
    'retry': 'REINTENTAR',
    'menu': 'MENÚ',
    'share_score': 'COMPARTIR PUNTAJE',
    'score_saved': 'Puntuación guardada',
    'select': 'SELECCIONAR',
    'buy': 'COMPRAR',
    'selected': 'SELECCIONADO',
    'time': 'TIEMPO',
    'xp_level_up': '¡Subiste al nivel {lvl}! (+{xp} XP)',
    'xp_gained': 'Ganaste +{xp} XP.',
    // Online / multiplayer
    'create_match': 'CREAR PARTIDA',
    'join_match': 'UNIRME',
    'waiting_rival': 'Esperando rival...',
    'invite_whatsapp': 'INVITAR POR WHATSAPP',
    'connecting': 'Conectando...',
    'connected': '¡Conectado!',
    'room_code': 'Código de sala',
    'enter_room_code': 'Ingresa el código de sala',
    'invite_text': '¡Te desafío en BeatTris! 🕹️🎵 Entra a mi partida usando este link: {link}',
    'you_win': '¡GANASTE!',
    'you_lose': 'PERDISTE',
    'rival_left': 'El rival abandonó la partida',
    'confirm_quit_title': '¿RETIRARSE?',
    'confirm_quit_body': '¿Estás seguro de retirarte de la partida? Se perderá tu progreso actual.',
    'confirm_quit_btn': 'RETIRARME',
    'confirm_restart_title': '¿REINICIAR?',
    'confirm_restart_body': '¿Estás seguro de reiniciar el juego? Se perderá tu progreso actual.',
    'confirm_restart_btn': 'REINICIAR',
    'cancel': 'CANCELAR',
  },
  'en': {
    'app_subtitle': 'PUZZLE GAME',
    'play': 'PLAY',
    'theme_shop': 'THEME SHOP',
    'daily_missions': 'DAILY MISSIONS',
    'scoreboard': 'LEADERBOARD',
    'no_scores': 'No scores yet',
    'col_name': 'Name',
    'col_mode': 'Game type',
    'col_level': 'Level',
    'col_score': 'Score',
    'mode_classic': 'CLASSIC',
    'mode_arena': 'ARENA',
    'mode_power': 'POWERS',
    'mode_multi': 'MULTI',
    'mode_online': 'ONLINE',
    'mode_settings': 'SETTINGS',
    'title_classic': 'CLASSIC MODE',
    'title_arena': 'ARENA MODE',
    'title_power': 'WITH POWERS',
    'title_multi': 'MULTIPLAYER',
    'title_online': 'ONLINE 1v1',
    'title_settings': 'SETTINGS',
    'desc_classic': 'The original puzzle. Clear lines with no time pressure.',
    'desc_arena': 'Survive the sand physics! Match colors from blocks that fall like dust.',
    'desc_power': 'Use special abilities like Laser and Bomb to smash blocks.',
    'desc_multi': 'Challenge your friends in local matches and show who rules.',
    'desc_online': 'Challenge anyone over the internet in a real-time 1v1 duel.',
    'desc_settings': 'Adjust volume, language and other preferences.',
    'music': 'MUSIC',
    'sfx': 'SFX',
    'language': 'LANGUAGE',
    'initial_level': 'STARTING LEVEL',
    'back_home': 'BACK TO HOME',
    'music_mode_on': 'MUSIC MODE ON',
    'music_mode_off': 'MUSIC MODE OFF',
    'music_mode_title': 'MUSIC MODE ENABLED!',
    'music_mode_body': 'Enjoy your own music in an immersive way. The game background will react and vibrate dynamically to the beat of your favorite songs!',
    'got_it': 'GOT IT!',
    'best': 'BEST',
    'score': 'SCORE',
    'lvl': 'LVL',
    'lines': 'LINES',
    'coins': 'COINS',
    'game_over': 'GAME OVER',
    'paused': 'PAUSED',
    'resume': 'RESUME',
    'restart': 'RESTART',
    'home': 'HOME',
    'retry': 'RETRY',
    'menu': 'MENU',
    'share_score': 'SHARE SCORE',
    'score_saved': 'Score saved',
    'select': 'SELECT',
    'buy': 'BUY',
    'selected': 'SELECTED',
    'time': 'TIME',
    'xp_level_up': 'You reached level {lvl}! (+{xp} XP)',
    'xp_gained': 'You earned +{xp} XP.',
    'create_match': 'CREATE MATCH',
    'join_match': 'JOIN',
    'waiting_rival': 'Waiting for opponent...',
    'invite_whatsapp': 'INVITE VIA WHATSAPP',
    'connecting': 'Connecting...',
    'connected': 'Connected!',
    'room_code': 'Room code',
    'enter_room_code': 'Enter room code',
    'invite_text': 'I challenge you in BeatTris! 🕹️🎵 Join my match using this link: {link}',
    'you_win': 'YOU WIN!',
    'you_lose': 'YOU LOSE',
    'rival_left': 'Opponent left the match',
    'confirm_quit_title': 'QUIT MATCH?',
    'confirm_quit_body': 'Are you sure you want to quit the match? Current progress will be lost.',
    'confirm_quit_btn': 'QUIT',
    'confirm_restart_title': 'RESTART?',
    'confirm_restart_body': 'Are you sure you want to restart? Current progress will be lost.',
    'confirm_restart_btn': 'RESTART',
    'cancel': 'CANCEL',
  },
  'pt': {
    'app_subtitle': 'JOGO DE QUEBRA-CABEÇA',
    'play': 'JOGAR',
    'theme_shop': 'LOJA DE TEMAS',
    'daily_missions': 'MISSÕES DIÁRIAS',
    'scoreboard': 'PLACAR',
    'no_scores': 'Ainda não há pontuações',
    'col_name': 'Nome',
    'col_mode': 'Tipo de jogo',
    'col_level': 'Nível',
    'col_score': 'Pontuação',
    'mode_classic': 'CLÁSSICO',
    'mode_arena': 'ARENA',
    'mode_power': 'PODERES',
    'mode_multi': 'MULTI',
    'mode_online': 'ONLINE',
    'mode_settings': 'AJUSTES',
    'title_classic': 'MODO CLÁSSICO',
    'title_arena': 'MODO ARENA',
    'title_power': 'COM PODERES',
    'title_multi': 'MULTIJOGADOR',
    'title_online': 'ONLINE 1v1',
    'title_settings': 'CONFIGURAÇÕES',
    'desc_classic': 'O quebra-cabeça original. Limpe linhas sem pressão de tempo.',
    'desc_arena': 'Sobreviva à física da areia! Conecte cores de blocos que caem como pó.',
    'desc_power': 'Use habilidades especiais como Laser e Bomba para destruir blocos.',
    'desc_multi': 'Desafie seus amigos em partidas locais e mostre quem manda.',
    'desc_online': 'Desafie qualquer um pela internet em um duelo 1v1 em tempo real.',
    'desc_settings': 'Ajuste volume, idioma e outras preferências.',
    'music': 'MÚSICA',
    'sfx': 'EFEITOS',
    'language': 'IDIOMA',
    'initial_level': 'NÍVEL INICIAL',
    'back_home': 'VOLTAR AO INÍCIO',
    'music_mode_on': 'MODO MÚSICA ON',
    'music_mode_off': 'MODO MÚSICA OFF',
    'music_mode_title': 'MODO MÚSICA ATIVADO!',
    'music_mode_body': 'Aproveite sua própria música de forma imersiva. O fundo do jogo vai reagir e vibrar dinamicamente no ritmo das suas músicas favoritas!',
    'got_it': 'ENTENDI!',
    'best': 'MELHOR',
    'score': 'PONTOS',
    'lvl': 'NÍVEL',
    'lines': 'LINHAS',
    'coins': 'MOEDAS',
    'game_over': 'FIM DE JOGO',
    'paused': 'PAUSADO',
    'resume': 'RETOMAR',
    'restart': 'REINICIAR',
    'home': 'INÍCIO',
    'retry': 'TENTAR DE NOVO',
    'menu': 'MENU',
    'share_score': 'COMPARTILHAR',
    'score_saved': 'Pontuação salva',
    'select': 'SELECIONAR',
    'buy': 'COMPRAR',
    'selected': 'SELECIONADO',
    'time': 'TEMPO',
    'xp_level_up': 'Você subiu para o nível {lvl}! (+{xp} XP)',
    'xp_gained': 'Você ganhou +{xp} XP.',
    'create_match': 'CRIAR PARTIDA',
    'join_match': 'ENTRAR',
    'waiting_rival': 'Aguardando oponente...',
    'invite_whatsapp': 'CONVIDAR PELO WHATSAPP',
    'connecting': 'Conectando...',
    'connected': 'Conectado!',
    'room_code': 'Código da sala',
    'enter_room_code': 'Digite o código da sala',
    'invite_text': 'Eu te desafio no BeatTris! 🕹️🎵 Entre na minha partida com este link: {link}',
    'you_win': 'VOCÊ VENCEU!',
    'you_lose': 'VOCÊ PERDEU',
    'rival_left': 'O oponente saiu da partida',
    'confirm_quit_title': 'SAIR DA PARTIDA?',
    'confirm_quit_body': 'Tem certeza de que deseja sair da partida? Seu progresso atual será perdido.',
    'confirm_quit_btn': 'SAIR',
    'confirm_restart_title': 'REINICIAR?',
    'confirm_restart_body': 'Tem certeza de que deseja reiniciar o jogo? Seu progresso atual será perdido.',
    'confirm_restart_btn': 'REINICIAR',
    'cancel': 'CANCELAR',
  },
  'zh': {
    'app_subtitle': '益智游戏',
    'play': '开始',
    'theme_shop': '主题商店',
    'daily_missions': '每日任务',
    'scoreboard': '排行榜',
    'no_scores': '暂无分数',
    'col_name': '名字',
    'col_mode': '游戏类型',
    'col_level': '等级',
    'col_score': '分数',
    'mode_classic': '经典',
    'mode_arena': '竞技场',
    'mode_power': '能力',
    'mode_multi': '多人',
    'mode_online': '在线',
    'mode_settings': '设置',
    'title_classic': '经典模式',
    'title_arena': '竞技场模式',
    'title_power': '能力模式',
    'title_multi': '多人游戏',
    'title_online': '在线 1v1',
    'title_settings': '设置',
    'desc_classic': '原汁原味的拼图。无时间压力地消除行。',
    'desc_arena': '在沙子的物理中生存下来！通过连接像沙子一样落下的方块的颜色。',
    'desc_power': '使用激光和炸弹等特殊技能来粉碎方块。',
    'desc_multi': '在本地比赛中挑战你的朋友，证明谁是王者。',
    'desc_online': '通过网络与任何人进行实时 1v1 对决。',
    'desc_settings': '调整音量、语言和其他偏好设置。',
    'music': '音乐',
    'sfx': '音效',
    'language': '语言',
    'initial_level': '起始等级',
    'back_home': '返回主页',
    'music_mode_on': '音乐模式 开',
    'music_mode_off': '音乐模式 关',
    'music_mode_title': '音乐模式已开启！',
    'music_mode_body': '以沉浸式的方式享受你自己的音乐。游戏背景将随着你最喜欢的歌曲节奏动态反应和震动！',
    'got_it': '明白了！',
    'best': '最佳',
    'score': '分数',
    'lvl': '等级',
    'lines': '行数',
    'coins': '金币',
    'game_over': '游戏结束',
    'paused': '已暂停',
    'resume': '继续',
    'restart': '重新开始',
    'home': '主页',
    'retry': '重试',
    'menu': '菜单',
    'share_score': '分享分数',
    'score_saved': '分数已保存',
    'select': '选择',
    'buy': '购买',
    'selected': '已选择',
    'time': '时间',
    'xp_level_up': '你升到了 {lvl} 级！(+{xp} XP)',
    'xp_gained': '你获得了 +{xp} XP。',
    'create_match': '创建对局',
    'join_match': '加入',
    'waiting_rival': '等待对手...',
    'invite_whatsapp': '通过 WhatsApp 邀请',
    'connecting': '连接中...',
    'connected': '已连接！',
    'room_code': '房间代码',
    'enter_room_code': '输入房间代码',
    'invite_text': '我在 BeatTris 向你发起挑战！🕹️🎵 使用此链接加入我的对局：{link}',
    'you_win': '你赢了！',
    'you_lose': '你输了',
    'rival_left': '对手已离开对局',
    'confirm_quit_title': '退出比赛？',
    'confirm_quit_body': '你确定要退出比赛吗？当前进度将会丢失。',
    'confirm_quit_btn': '退出',
    'confirm_restart_title': '重新开始？',
    'confirm_restart_body': '你确定要重新开始游戏吗？当前进度将会丢失。',
    'confirm_restart_btn': '重新开始',
    'cancel': '取消',
  },
  'ru': {
    'app_subtitle': 'ГОЛОВОЛОМКА',
    'play': 'ИГРАТЬ',
    'theme_shop': 'МАГАЗИН ТЕМ',
    'daily_missions': 'ЕЖЕДНЕВНЫЕ ЗАДАНИЯ',
    'scoreboard': 'ТАБЛИЦА ЛИДЕРОВ',
    'no_scores': 'Пока нет результатов',
    'col_name': 'Имя',
    'col_mode': 'Режим',
    'col_level': 'Уровень',
    'col_score': 'Очки',
    'mode_classic': 'КЛАССИКА',
    'mode_arena': 'АРЕНА',
    'mode_power': 'СИЛЫ',
    'mode_multi': 'МУЛЬТИ',
    'mode_online': 'ОНЛАЙН',
    'mode_settings': 'НАСТРОЙКИ',
    'title_classic': 'КЛАССИЧЕСКИЙ РЕЖИМ',
    'title_arena': 'РЕЖИМ АРЕНА',
    'title_power': 'СО СПОСОБНОСТЯМИ',
    'title_multi': 'МУЛЬТИПЛЕЕР',
    'title_online': 'ОНЛАЙН 1 на 1',
    'title_settings': 'НАСТРОЙКИ',
    'desc_classic': 'Оригинальная головоломка. Убирайте линии без спешки.',
    'desc_arena': 'Выживите в песочной физике! Соединяйте цвета из блоков, которые падают как пыль.',
    'desc_power': 'Используйте лазер и бомбу, чтобы крушить блоки.',
    'desc_multi': 'Бросьте вызов друзьям в локальных матчах.',
    'desc_online': 'Сразитесь с кем угодно по сети в дуэли 1 на 1 в реальном времени.',
    'desc_settings': 'Настройте громкость, язык и другие параметры.',
    'music': 'МУЗЫКА',
    'sfx': 'ЭФФЕКТЫ',
    'language': 'ЯЗЫК',
    'initial_level': 'НАЧАЛЬНЫЙ УРОВЕНЬ',
    'back_home': 'НА ГЛАВНУЮ',
    'music_mode_on': 'РЕЖИМ МУЗЫКИ ВКЛ',
    'music_mode_off': 'РЕЖИМ МУЗЫКИ ВЫКЛ',
    'music_mode_title': 'РЕЖИМ МУЗЫКИ ВКЛЮЧЁН!',
    'music_mode_body': 'Наслаждайтесь своей музыкой с эффектом погружения. Фон игры будет реагировать и вибрировать в ритме ваших любимых песен!',
    'got_it': 'ПОНЯТНО!',
    'best': 'ЛУЧШИЙ',
    'score': 'ОЧКИ',
    'lvl': 'УР',
    'lines': 'ЛИНИИ',
    'coins': 'МОНЕТЫ',
    'game_over': 'ИГРА ОКОНЧЕНА',
    'paused': 'ПАУЗА',
    'resume': 'ПРОДОЛЖИТЬ',
    'restart': 'ЗАНОВО',
    'home': 'ГЛАВНАЯ',
    'retry': 'ПОВТОР',
    'menu': 'МЕНЮ',
    'share_score': 'ПОДЕЛИТЬСЯ',
    'score_saved': 'Результат сохранён',
    'select': 'ВЫБРАТЬ',
    'buy': 'КУПИТЬ',
    'selected': 'ВЫБРАНО',
    'time': 'ВРЕМЯ',
    'xp_level_up': 'Вы достигли уровня {lvl}! (+{xp} XP)',
    'xp_gained': 'Вы получили +{xp} XP.',
    'create_match': 'СОЗДАТЬ МАТЧ',
    'join_match': 'ВОЙТИ',
    'waiting_rival': 'Ожидание соперника...',
    'invite_whatsapp': 'ПРИГЛАСИТЬ В WHATSAPP',
    'connecting': 'Подключение...',
    'connected': 'Подключено!',
    'room_code': 'Код комнаты',
    'enter_room_code': 'Введите код комнаты',
    'invite_text': 'Бросаю тебе вызов в BeatTris! 🕹️🎵 Заходи в мой матч по ссылке: {link}',
    'you_win': 'ПОБЕДА!',
    'you_lose': 'ПОРАЖЕНИЕ',
    'rival_left': 'Соперник покинул матч',
    'confirm_quit_title': 'ВЫЙТИ ИЗ МАТЧА?',
    'confirm_quit_body': 'Вы уверены, что хотите покинуть матч? Текущий прогресс будет потерян.',
    'confirm_quit_btn': 'ВЫЙТИ',
    'confirm_restart_title': 'ПЕРЕЗАПУСТИТЬ?',
    'confirm_restart_body': 'Вы уверены, что хотите перезапустить игру? Текущий прогресс будет потерян.',
    'confirm_restart_btn': 'ПЕРЕЗАПУСТИТЬ',
    'cancel': 'ОТМЕНА',
  },
};
