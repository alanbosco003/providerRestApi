import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/apihelper.dart';
import '../models/post.dart';
import '../provider/homepageprovider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  ScrollController _scrollController = ScrollController();

  _showSnackbar(String message, {required Color bgColor}) {
    _globalKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.white),
    );
  }

  _hideSnackbar() {
    _globalKey.currentState!.hideCurrentSnackBar();
  }

  _getPosts({bool refresh = true}) async {
    var provider = Provider.of<HomePageProvider>(context, listen: false);
    if (!provider.shouldRefresh) {
      _showSnackbar('That\'s it for now!', bgColor: Colors.red);
      return;
    }
    if (refresh) _showSnackbar('Loading more...', bgColor: Colors.green);

    var postsResponse = await APIHelper.getPosts(
      limit: 20,
      page: provider.currentPage,
    );
    if (postsResponse.isSuccessful) {
      if (postsResponse.data!.isNotEmpty) {
        if (refresh) {
          provider.mergePostsList(postsResponse.data!, notify: false);
        } else {
          provider.setPostsList(postsResponse.data!, notify: false);
        }
        provider.setCurrentPage(provider.currentPage + 1);
      } else {
        provider.setShouldRefresh(false);
      }
    } else {
      _showSnackbar(postsResponse.message!, bgColor: Colors.red);
    }
    provider.setIsHomePageProcessing(false);
    _hideSnackbar();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        if (_scrollController.offset ==
            _scrollController.position.maxScrollExtent) {
          _getPosts();
        }
      }
    });
    _getPosts(refresh: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      appBar: AppBar(
        title: const Text('Demo app'),
      ),
      body: Consumer<HomePageProvider>(
        builder: (_, provider, __) => provider.isHomePageProcessing
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : provider.postsListLength > 0
                ? ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    controller: _scrollController,
                    itemBuilder: (_, index) {
                      Post post = provider.getPostByIndex(index);
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(50))),
                          child: Center(
                            child: Text(
                              post.id.toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        title: Text(post.name.toString()),
                        subtitle: Text(
                          post.address.city.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          post.phone.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                    itemCount: provider.postsListLength,
                  )
                : const Center(
                    child: Text('Nothing to show here!'),
                  ),
      ),
    );
  }
}
