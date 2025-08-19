// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get settings => '設定';

  @override
  String get share => '共有';

  @override
  String get theme => 'テーマ';

  @override
  String get launch_url_error => '指定されたURLを開くことが出来ませんでした';

  @override
  String get export_as_mp3 => 'MP3としてエクスポート';

  @override
  String get open_in_youtube => 'YouTubeで開く';

  @override
  String get refresh_all => 'キューの再読み込み';

  @override
  String get useful_functions => '便利機能';

  @override
  String get general_settings => '基本設定';

  @override
  String get auto_download => '自動ダウンロード';

  @override
  String get auto_download_description => '曲の追加時に自動的にダウンロードします';

  @override
  String get network_not_accessible => 'ネットワークにアクセス出来ません';

  @override
  String get network_not_connected => 'ネットワークに接続されていません';

  @override
  String get song_unplayable => 'この曲を再生することが出来ません';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get ok => 'OK';

  @override
  String get delete_from_local => 'ローカルストレージから削除';

  @override
  String get delete_from_local_confirm_message => 'この曲をローカルから削除しますか？';

  @override
  String get song_history => '再生履歴';

  @override
  String get go_back => '戻る';

  @override
  String get no_song_history => '再生履歴はありません';

  @override
  String get song_unable_to_load => '曲を読み込むことが出来ませんでした';

  @override
  String get delete_from_history => '再生履歴から削除';

  @override
  String get delete_from_history_confirm_message => 'この曲を再生履歴から削除しますか？';

  @override
  String get list_separator => '、';

  @override
  String theme_names(String theme) {
    String _temp0 = intl.Intl.selectLogic(
      theme,
      {
        'dark': 'ダーク',
        'light': 'ライト',
        'other': '$theme',
      },
    );
    return '$_temp0';
  }

  @override
  String get shuffle => 'シャッフル';

  @override
  String get play_previous_song => '一つ前の曲を再生';

  @override
  String get downloading => 'ダウンロード中';

  @override
  String get menu => 'メニュー';

  @override
  String get downloading_automatically => '自動ダウンロード中';

  @override
  String get play => '再生';

  @override
  String get pause => '一時停止';

  @override
  String get play_next_song => '次の曲を再生';

  @override
  String get clear => 'クリア';

  @override
  String get search => '検索';

  @override
  String get more_actions => 'その他';

  @override
  String loading_songs(num count) {
    return '$count曲を読み込み中';
  }

  @override
  String get invalid_url => '無効なURLです';

  @override
  String get saving => 'ローカルに保存中';

  @override
  String get repeat => 'リピート';

  @override
  String get off => 'OFF';

  @override
  String get on => 'ON';

  @override
  String get song => '曲';

  @override
  String get queue => 'キュー';

  @override
  String get external_playlist_empty => '外部プレイリストに曲がありません';

  @override
  String get song_title => '曲名';

  @override
  String get song_artist => 'アーティスト名';

  @override
  String get previous => '戻る';

  @override
  String get next => '次へ';

  @override
  String get finish => '完了';

  @override
  String get lyrics => '歌詞';

  @override
  String get close => '閉じる';

  @override
  String get lyrics_not_found => '歌詞が見つかりませんでした';

  @override
  String get login => 'サインイン';

  @override
  String get sign_up => 'アカウント作成';

  @override
  String get welcome_back => 'おかえりなさい';

  @override
  String get welcome => 'ようこそ';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get invalid_email => '無効なメールアドレス';

  @override
  String get input_password => 'パスワードを入力してください';

  @override
  String get invalid_password_format => 'パスワードの形式が正しくありません';

  @override
  String get invalid_password_format_in_detail => '半角英字、数字、記号を組み合わせて 8 文字以上 32 文字以内 で入力してください';

  @override
  String get logout => 'ログアウト';

  @override
  String get exit_app => 'アプリを閉じる';

  @override
  String get something_went_wrong => 'エラーが発生しました';

  @override
  String get invalid_email_or_password => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get disabled_user => 'このアカウントは凍結されています';

  @override
  String get sign_up_message => 'アカウントをお持ちではない場合、%作成%できます。';

  @override
  String get login_message => 'すでにアカウントをお持ちですか? %サインイン%';

  @override
  String get email_already_in_use => 'このメールアドレスはすでに使用されています';

  @override
  String get weak_password => 'パスワード強度が足りません';

  @override
  String get verify_email => 'メールアドレスの認証';

  @override
  String get send => '送信';

  @override
  String get forgot_password => 'パスワードを忘れた場合';

  @override
  String get reset_password => 'パスワードのリセット';

  @override
  String get reset_password_email_sent => 'パスワードリセットのメールを送信しました';

  @override
  String get sign_in_with_google => 'Google でログイン';

  @override
  String get app_info => 'アプリ情報';

  @override
  String get copied_to_clipboard => 'クリップボードにコピーしました';

  @override
  String get selected_songs => '選択中の曲';

  @override
  String get offline_search => 'オフライン検索';

  @override
  String get share_mp3 => 'MP3ファイルを共有';

  @override
  String get disable_interruptions => '音楽の妨害を阻止';

  @override
  String get disable_interruptions_description => '他のアプリによる音楽の一時停止などの妨害を無効化します。';

  @override
  String get restart_required => 'このオプションを適用するにはアプリの再起動が必要です。';

  @override
  String get audio_channel => 'オーディオチャンネル';

  @override
  String audio_channels(String channel) {
    String _temp0 = intl.Intl.selectLogic(
      channel,
      {
        'media': 'メディア',
        'call': '通話',
        'call_speaker': '通話 (スピーカー)',
        'notification': '着信音と通知',
        'alarm': 'アラーム',
        'other': '$channel',
      },
    );
    return '$_temp0';
  }

  @override
  String get from_clipboard => 'クリップボードから';

  @override
  String get no_text_in_clipboard => 'クリップボードにテキストがありません';

  @override
  String get playlist => 'プレイリスト';

  @override
  String get create_playlist => 'プレイリストを作成';

  @override
  String get playlist_name => 'プレイリスト名';

  @override
  String get create => '作成';

  @override
  String get delete_playlists => 'プレイリストを削除';

  @override
  String get delete_playlists_message => '選択したプレイリストを削除しますか？';

  @override
  String get store_songs => '曲を保存';

  @override
  String get store_songs_explanation => 'プレイリストには保存された曲のみを追加できます。プレイリスト内の保存されていない曲を保存しますか？';

  @override
  String get empty_playlist => '空のプレイリスト';

  @override
  String selected(num count) {
    return '選択中 ($count個)';
  }
}
