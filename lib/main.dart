import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

const String appId = '';
const String channelName = 'test_channel';
const String token =
    '';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agora 영상통화 데모',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VideoCallPage(),
    );
  }
}

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late final RtcEngine _engine;
  int? _remoteUid;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.camera, Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: appId));
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );
  }

  Future<void> _join() async {
    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
      uid: 0,
    );
  }

  Future<void> _leave() async {
    await _engine.leaveChannel();
    setState(() {
      _isJoined = false;
      _remoteUid = null;
    });
  }

  @override
  void dispose() {
    _engine.release();
    super.dispose();
  }

  Widget _renderLocalPreview() {
    if (_isJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return const Center(child: Text('채널에 참여해 주세요'));
    }
  }

  Widget _renderRemoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channelName),
        ),
      );
    } else {
      return const Center(child: Text('상대방을 기다리는 중...'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agora 영상통화 데모')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _renderLocalPreview()),
                Expanded(child: _renderRemoteVideo()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isJoined ? null : _join,
                  child: const Text('참여'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isJoined ? _leave : null,
                  child: const Text('나가기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
