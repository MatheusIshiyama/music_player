import 'package:flutter/material.dart';
import 'package:flute_music_player/flute_music_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MusicPlayer(),
    );
  }
}

enum PlayerState { stopped, playing, paused }

class MusicPlayer extends StatefulWidget {
  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  List<Song> _songs;
  IconData playBtn = Icons.play_arrow;

  var songIndex = 0;

  Duration duration;
  Duration position;

  MusicFinder audioPlayer;

  String localFilePath;

  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';
  get positionText =>
      position != null ? position.toString().split('.').first : '';

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
  }

  Future initAudioPlayer() async {
    audioPlayer = new MusicFinder();
    var songs = await MusicFinder.allSongs();

    audioPlayer.setDurationHandler(
      (d) => setState(() => duration = d),
    );

    audioPlayer.setPositionHandler(
      (p) => setState(() => position = p),
    );

    audioPlayer.setCompletionHandler(() {
      onComplete();
      setState(() => position = duration);
    });

    audioPlayer.setErrorHandler(
      (msg) {
        setState(() {
          playerState = PlayerState.stopped;
          duration = new Duration(seconds: 0);
          position = new Duration(seconds: 0);
        });
      },
    );

    setState(() => _songs = songs);
  }

  Future play() async {
    final result = await audioPlayer.play(localFilePath, isLocal: true);
    if (result == 1)
      setState(() {
        playerState = PlayerState.playing;
        playBtn = Icons.pause;
      });
  }

  Future _playLocal() async {
    audioPlayer.stop();
    final result = await audioPlayer.play(localFilePath, isLocal: true);
    if (result == 1)
      setState(() {
        playerState = PlayerState.playing;
        playBtn = Icons.pause;
      });
  }

  Future pause() async {
    final result = await audioPlayer.pause();
    if (result == 1)
      setState(() {
        playerState = PlayerState.paused;
        playBtn = Icons.play_arrow;
      });
  }

  Future previous() async {
    audioPlayer.stop();
    if (songIndex == 0) {
      setState(() {
        songIndex = _songs.length - 1;
      });
    } else {
      setState(() {
        songIndex--;
      });
    }
    setState(() {
      localFilePath = _songs[songIndex].uri;
    });
    play();
  }

  Future next() async {
    await audioPlayer.stop();
    if (songIndex == _songs.length - 1) {
      setState(() {
        songIndex = 0;
      });
    } else {
      setState(() {
        songIndex++;
      });
    }
    setState(() {
      localFilePath = _songs[songIndex].uri;
    });
    play();
  }

  void onComplete() async {
    next();
  }

  @override
  void dispose() async {
    super.dispose();
    await audioPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.center,
              colors: [
                Colors.indigo[900],
                Colors.black,
              ]),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 50),
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Text(
                    'Music Player',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 18,
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: _songs.length,
                    itemBuilder: (context, int index) {
                      return InkWell(
                        onTap: () => {
                          songIndex = index,
                          localFilePath = _songs[index].uri,
                          _playLocal(),
                        },
                        child: Container(
                          height: 75,
                          margin: EdgeInsets.only(left: 10, right: 10),
                          child: Card(
                            color: Colors.white10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 75,
                                  width: 75,
                                  child: Icon(
                                    Icons.music_note_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  height: 75,
                                  width: 285,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _songs[index].title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.indigo[900],
                            Colors.black,
                          ]),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding:
                              EdgeInsets.only(left: 15, right: 15, top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                positionText,
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                durationText,
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          child: Slider.adaptive(
                            value: position != null
                                ? position.inSeconds.toDouble()
                                : 0,
                            max: duration != null
                                ? duration.inSeconds.toDouble()
                                : 0,
                            onChanged: (value) {
                              audioPlayer.seek(value.toDouble());
                            },
                          ),
                        ),
                        Text(
                          '${_songs[songIndex].title}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.skip_previous),
                                color: Colors.white,
                                iconSize: 40,
                                onPressed: () {
                                  previous();
                                },
                              ),
                              IconButton(
                                icon: Icon(playBtn),
                                color: Colors.white,
                                iconSize: 50,
                                onPressed: () {
                                  if (playerState == PlayerState.playing) {
                                    pause();
                                  } else {
                                    play();
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.skip_next),
                                color: Colors.white,
                                iconSize: 40,
                                onPressed: () {
                                  next();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
