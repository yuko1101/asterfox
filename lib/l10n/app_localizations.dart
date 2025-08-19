import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @launch_url_error.
  ///
  /// In en, this message translates to:
  /// **'The URL is not valid.'**
  String get launch_url_error;

  /// No description provided for @export_as_mp3.
  ///
  /// In en, this message translates to:
  /// **'Export as MP3'**
  String get export_as_mp3;

  /// No description provided for @open_in_youtube.
  ///
  /// In en, this message translates to:
  /// **'Open in YouTube'**
  String get open_in_youtube;

  /// No description provided for @refresh_all.
  ///
  /// In en, this message translates to:
  /// **'Refresh all songs'**
  String get refresh_all;

  /// No description provided for @useful_functions.
  ///
  /// In en, this message translates to:
  /// **'Useful Functions'**
  String get useful_functions;

  /// No description provided for @general_settings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get general_settings;

  /// No description provided for @auto_download.
  ///
  /// In en, this message translates to:
  /// **'Auto Download'**
  String get auto_download;

  /// No description provided for @auto_download_description.
  ///
  /// In en, this message translates to:
  /// **'Download songs automatically when you add them to the queue.'**
  String get auto_download_description;

  /// No description provided for @network_not_accessible.
  ///
  /// In en, this message translates to:
  /// **'Network is not accessible'**
  String get network_not_accessible;

  /// No description provided for @network_not_connected.
  ///
  /// In en, this message translates to:
  /// **'Network is not connected'**
  String get network_not_connected;

  /// No description provided for @song_unplayable.
  ///
  /// In en, this message translates to:
  /// **'Song is not playable'**
  String get song_unplayable;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @delete_from_local.
  ///
  /// In en, this message translates to:
  /// **'Delete from local storage'**
  String get delete_from_local;

  /// No description provided for @delete_from_local_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this song from your local storage?'**
  String get delete_from_local_confirm_message;

  /// No description provided for @song_history.
  ///
  /// In en, this message translates to:
  /// **'Song History'**
  String get song_history;

  /// No description provided for @go_back.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get go_back;

  /// No description provided for @no_song_history.
  ///
  /// In en, this message translates to:
  /// **'No song history'**
  String get no_song_history;

  /// No description provided for @song_unable_to_load.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the song'**
  String get song_unable_to_load;

  /// No description provided for @delete_from_history.
  ///
  /// In en, this message translates to:
  /// **'Delete from history'**
  String get delete_from_history;

  /// No description provided for @delete_from_history_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this song from your history?'**
  String get delete_from_history_confirm_message;

  /// No description provided for @list_separator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get list_separator;

  /// No description provided for @theme_names.
  ///
  /// In en, this message translates to:
  /// **'{theme, select, dark {Dark} light {Light} other {{theme}}}'**
  String theme_names(String theme);

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @play_previous_song.
  ///
  /// In en, this message translates to:
  /// **'Play the previous song'**
  String get play_previous_song;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @downloading_automatically.
  ///
  /// In en, this message translates to:
  /// **'Auto Download'**
  String get downloading_automatically;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @play_next_song.
  ///
  /// In en, this message translates to:
  /// **'Play the next song'**
  String get play_next_song;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @more_actions.
  ///
  /// In en, this message translates to:
  /// **'More Actions'**
  String get more_actions;

  /// No description provided for @loading_songs.
  ///
  /// In en, this message translates to:
  /// **'Loading {count} song(s)'**
  String loading_songs(num count);

  /// No description provided for @invalid_url.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalid_url;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get off;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get on;

  /// No description provided for @song.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get song;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @external_playlist_empty.
  ///
  /// In en, this message translates to:
  /// **'The external playlist is empty'**
  String get external_playlist_empty;

  /// No description provided for @song_title.
  ///
  /// In en, this message translates to:
  /// **'Song Title'**
  String get song_title;

  /// No description provided for @song_artist.
  ///
  /// In en, this message translates to:
  /// **'Song Artist'**
  String get song_artist;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @lyrics_not_found.
  ///
  /// In en, this message translates to:
  /// **'Lyrics not found'**
  String get lyrics_not_found;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get sign_up;

  /// No description provided for @welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcome_back;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalid_email;

  /// No description provided for @input_password.
  ///
  /// In en, this message translates to:
  /// **'Please input your password'**
  String get input_password;

  /// No description provided for @invalid_password_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid password format'**
  String get invalid_password_format;

  /// No description provided for @invalid_password_format_in_detail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a combination of letters, numbers, and symbols with a minimum length of 8 and a maximum length of 32 characters.'**
  String get invalid_password_format_in_detail;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @exit_app.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exit_app;

  /// No description provided for @something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get something_went_wrong;

  /// No description provided for @invalid_email_or_password.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalid_email_or_password;

  /// No description provided for @disabled_user.
  ///
  /// In en, this message translates to:
  /// **'This account is frozen'**
  String get disabled_user;

  /// No description provided for @sign_up_message.
  ///
  /// In en, this message translates to:
  /// **'No account? %Sign Up%'**
  String get sign_up_message;

  /// No description provided for @login_message.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? %Login%'**
  String get login_message;

  /// No description provided for @email_already_in_use.
  ///
  /// In en, this message translates to:
  /// **'This email address is already in use'**
  String get email_already_in_use;

  /// No description provided for @weak_password.
  ///
  /// In en, this message translates to:
  /// **'This password is too weak'**
  String get weak_password;

  /// No description provided for @verify_email.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verify_email;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// No description provided for @reset_password.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get reset_password;

  /// No description provided for @reset_password_email_sent.
  ///
  /// In en, this message translates to:
  /// **'Reset Password email has been sent'**
  String get reset_password_email_sent;

  /// No description provided for @sign_in_with_google.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get sign_in_with_google;

  /// No description provided for @app_info.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get app_info;

  /// No description provided for @copied_to_clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to Clipboard'**
  String get copied_to_clipboard;

  /// No description provided for @selected_songs.
  ///
  /// In en, this message translates to:
  /// **'Selected Songs'**
  String get selected_songs;

  /// No description provided for @offline_search.
  ///
  /// In en, this message translates to:
  /// **'Offline Search'**
  String get offline_search;

  /// No description provided for @share_mp3.
  ///
  /// In en, this message translates to:
  /// **'Share MP3 File'**
  String get share_mp3;

  /// No description provided for @disable_interruptions.
  ///
  /// In en, this message translates to:
  /// **'Disable music interruptions'**
  String get disable_interruptions;

  /// No description provided for @disable_interruptions_description.
  ///
  /// In en, this message translates to:
  /// **'Protects music from being interrupted by other applications.'**
  String get disable_interruptions_description;

  /// No description provided for @restart_required.
  ///
  /// In en, this message translates to:
  /// **'Changing this option requires a restart to take effect.'**
  String get restart_required;

  /// No description provided for @audio_channel.
  ///
  /// In en, this message translates to:
  /// **'Audio Channel'**
  String get audio_channel;

  /// No description provided for @audio_channels.
  ///
  /// In en, this message translates to:
  /// **'{channel, select, media {Media} call {Call} call_speaker {Call (Speaker)} notification {Ring & notification} alarm {Alarm} other {{channel}}}'**
  String audio_channels(String channel);

  /// No description provided for @from_clipboard.
  ///
  /// In en, this message translates to:
  /// **'From Clipboard'**
  String get from_clipboard;

  /// No description provided for @no_text_in_clipboard.
  ///
  /// In en, this message translates to:
  /// **'No text in clipboard'**
  String get no_text_in_clipboard;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// No description provided for @create_playlist.
  ///
  /// In en, this message translates to:
  /// **'Create a playlist'**
  String get create_playlist;

  /// No description provided for @playlist_name.
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlist_name;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete_playlists.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlists'**
  String get delete_playlists;

  /// No description provided for @delete_playlists_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected playlists?'**
  String get delete_playlists_message;

  /// No description provided for @store_songs.
  ///
  /// In en, this message translates to:
  /// **'Store Songs'**
  String get store_songs;

  /// No description provided for @store_songs_explanation.
  ///
  /// In en, this message translates to:
  /// **'Playlists cannot have non-stored songs. Would you like to store the non-stored songs in the playlist?'**
  String get store_songs_explanation;

  /// No description provided for @empty_playlist.
  ///
  /// In en, this message translates to:
  /// **'Empty Playlist'**
  String get empty_playlist;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected ({count})'**
  String selected(num count);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
