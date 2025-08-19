// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get share => 'Share';

  @override
  String get theme => 'Theme';

  @override
  String get launch_url_error => 'The URL is not valid.';

  @override
  String get export_as_mp3 => 'Export as MP3';

  @override
  String get open_in_youtube => 'Open in YouTube';

  @override
  String get refresh_all => 'Refresh all songs';

  @override
  String get useful_functions => 'Useful Functions';

  @override
  String get general_settings => 'General Settings';

  @override
  String get auto_download => 'Auto Download';

  @override
  String get auto_download_description => 'Download songs automatically when you add them to the queue.';

  @override
  String get network_not_accessible => 'Network is not accessible';

  @override
  String get network_not_connected => 'Network is not connected';

  @override
  String get song_unplayable => 'Song is not playable';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String get delete_from_local => 'Delete from local storage';

  @override
  String get delete_from_local_confirm_message => 'Are you sure you want to delete this song from your local storage?';

  @override
  String get song_history => 'Song History';

  @override
  String get go_back => 'Go back';

  @override
  String get no_song_history => 'No song history';

  @override
  String get song_unable_to_load => 'Unable to load the song';

  @override
  String get delete_from_history => 'Delete from history';

  @override
  String get delete_from_history_confirm_message => 'Are you sure you want to delete this song from your history?';

  @override
  String get list_separator => ', ';

  @override
  String theme_names(String theme) {
    String _temp0 = intl.Intl.selectLogic(
      theme,
      {
        'dark': 'Dark',
        'light': 'Light',
        'other': '$theme',
      },
    );
    return '$_temp0';
  }

  @override
  String get shuffle => 'Shuffle';

  @override
  String get play_previous_song => 'Play the previous song';

  @override
  String get downloading => 'Downloading';

  @override
  String get menu => 'Menu';

  @override
  String get downloading_automatically => 'Auto Download';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get play_next_song => 'Play the next song';

  @override
  String get clear => 'Clear';

  @override
  String get search => 'Search';

  @override
  String get more_actions => 'More Actions';

  @override
  String loading_songs(num count) {
    return 'Loading $count song(s)';
  }

  @override
  String get invalid_url => 'Invalid URL';

  @override
  String get saving => 'Saving';

  @override
  String get repeat => 'Repeat';

  @override
  String get off => 'OFF';

  @override
  String get on => 'ON';

  @override
  String get song => 'Song';

  @override
  String get queue => 'Queue';

  @override
  String get external_playlist_empty => 'The external playlist is empty';

  @override
  String get song_title => 'Song Title';

  @override
  String get song_artist => 'Song Artist';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get close => 'Close';

  @override
  String get lyrics_not_found => 'Lyrics not found';

  @override
  String get login => 'Login';

  @override
  String get sign_up => 'Sign Up';

  @override
  String get welcome_back => 'Welcome back';

  @override
  String get welcome => 'Welcome';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get invalid_email => 'Invalid email';

  @override
  String get input_password => 'Please input your password';

  @override
  String get invalid_password_format => 'Invalid password format';

  @override
  String get invalid_password_format_in_detail => 'Please enter a combination of letters, numbers, and symbols with a minimum length of 8 and a maximum length of 32 characters.';

  @override
  String get logout => 'Log Out';

  @override
  String get exit_app => 'Exit App';

  @override
  String get something_went_wrong => 'Something went wrong';

  @override
  String get invalid_email_or_password => 'Invalid email or password';

  @override
  String get disabled_user => 'This account is frozen';

  @override
  String get sign_up_message => 'No account? %Sign Up%';

  @override
  String get login_message => 'Already have an account? %Login%';

  @override
  String get email_already_in_use => 'This email address is already in use';

  @override
  String get weak_password => 'This password is too weak';

  @override
  String get verify_email => 'Verify Email';

  @override
  String get send => 'Send';

  @override
  String get forgot_password => 'Forgot Password?';

  @override
  String get reset_password => 'Reset Password';

  @override
  String get reset_password_email_sent => 'Reset Password email has been sent';

  @override
  String get sign_in_with_google => 'Sign in with Google';

  @override
  String get app_info => 'App Information';

  @override
  String get copied_to_clipboard => 'Copied to Clipboard';

  @override
  String get selected_songs => 'Selected Songs';

  @override
  String get offline_search => 'Offline Search';

  @override
  String get share_mp3 => 'Share MP3 File';

  @override
  String get disable_interruptions => 'Disable music interruptions';

  @override
  String get disable_interruptions_description => 'Protects music from being interrupted by other applications.';

  @override
  String get restart_required => 'Changing this option requires a restart to take effect.';

  @override
  String get audio_channel => 'Audio Channel';

  @override
  String audio_channels(String channel) {
    String _temp0 = intl.Intl.selectLogic(
      channel,
      {
        'media': 'Media',
        'call': 'Call',
        'call_speaker': 'Call (Speaker)',
        'notification': 'Ring & notification',
        'alarm': 'Alarm',
        'other': '$channel',
      },
    );
    return '$_temp0';
  }

  @override
  String get from_clipboard => 'From Clipboard';

  @override
  String get no_text_in_clipboard => 'No text in clipboard';

  @override
  String get playlist => 'Playlist';

  @override
  String get create_playlist => 'Create a playlist';

  @override
  String get playlist_name => 'Playlist Name';

  @override
  String get create => 'Create';

  @override
  String get delete_playlists => 'Delete Playlists';

  @override
  String get delete_playlists_message => 'Are you sure you want to delete the selected playlists?';

  @override
  String get store_songs => 'Store Songs';

  @override
  String get store_songs_explanation => 'Playlists cannot have non-stored songs. Would you like to store the non-stored songs in the playlist?';

  @override
  String get empty_playlist => 'Empty Playlist';

  @override
  String selected(num count) {
    return 'Selected ($count)';
  }
}
