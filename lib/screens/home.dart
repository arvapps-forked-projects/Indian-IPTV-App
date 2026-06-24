import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ip_tv/model/channel.dart';
import 'package:ip_tv/model/stream_source.dart';
import 'package:ip_tv/screens/player.dart';

import '../provider/channels_provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> with SingleTickerProviderStateMixin {
  List<Channel> channels = [];
  List<Channel> filteredChannels = [];
  List<StreamSource> streamSources = [];
  StreamSource? selectedSource;
  final ChannelsProvider channelsProvider = ChannelsProvider();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStreamSources();
  }

  Future<void> fetchStreamSources() async {
    try {
      final sources = await channelsProvider.fetchStreamSources();
      setState(() {
        streamSources = sources;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('There was a problem loading stream categories'),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchChannels(StreamSource source) async {
    setState(() {
      _isLoading = true;
      selectedSource = source;
    });

    try {
      final data = await channelsProvider.fetchM3UFile(source.streamUrl);
      setState(() {
        channels = data;
        filteredChannels = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('There was a problem loading channels'),
          ),
        );
      }
      setState(() {
        selectedSource = null;
        _isLoading = false;
      });
    }
  }

  void backToCategories() {
    setState(() {
      selectedSource = null;
      channels = [];
      filteredChannels = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(selectedSource?.name ?? 'Live Tv'),
          leading: selectedSource != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: backToCategories,
                )
              : null,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : selectedSource == null
                ? _buildCategoryGrid()
                : sampleVideoGrid(),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (streamSources.isEmpty) {
      return const Center(child: Text('No stream categories available'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.2,
      ),
      itemCount: streamSources.length,
      itemBuilder: (context, index) {
        final source = streamSources[index];
        return InkWell(
          onTap: () => fetchChannels(source),
          child: Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  source.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget sampleVideoGrid() {
    return SingleChildScrollView(
      child: Column(
        children: [
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
            ),
            children: filteredChannels
                .map((channel) => InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => Player(
                              url: channel.streamUrl,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: Column(
                          children: [
                            Image.network(
                              channel.logoUrl,
                              height: 150,
                              width: 150,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/tv-icon.png',
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                            const SizedBox(height: 8.0),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  channel.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
