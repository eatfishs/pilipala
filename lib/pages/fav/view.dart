import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pilipala/common/skeleton/video_card_h.dart';
import 'package:pilipala/common/widgets/http_error.dart';
import 'package:pilipala/pages/fav/index.dart';
import 'package:pilipala/pages/fav/widgets/item.dart';
import 'package:pilipala/utils/route_push.dart';

class FavPage extends StatefulWidget {
  const FavPage({super.key});

  @override
  State<FavPage> createState() => _FavPageState();
}

class _FavPageState extends State<FavPage> {
  final FavController _favController = Get.put(FavController());
  late Future _futureBuilderFuture;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    _futureBuilderFuture = _favController.queryFavFolder();
    scrollController = _favController.scrollController;
    scrollController.addListener(
      () {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 300) {
          EasyThrottle.throttle('history', const Duration(seconds: 1), () {
            _favController.onLoad();
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Obx(() => Text(
              '${_favController.isOwner.value ? '我' : 'Ta'}的收藏',
              style: Theme.of(context).textTheme.titleMedium,
            )),
        actions: [
          Obx(() => !_favController.isOwner.value
              ? IconButton(
                  onPressed: () =>
                      Get.toNamed('/subscription?mid=${_favController.mid}'),
                  icon: const Icon(Icons.subscriptions_outlined, size: 21),
                  tooltip: 'Ta的订阅',
                )
              : const SizedBox.shrink()),

          // 新建收藏夹
          Obx(() => _favController.isOwner.value
              ? IconButton(
                  onPressed: () async {
                    await Get.toNamed('/favEdit');
                    _favController.hasMore.value = true;
                    _favController.currentPage = 1;
                    setState(() {
                      _futureBuilderFuture = _favController.queryFavFolder();
                    });
                  },
                  icon: const Icon(Icons.add_outlined),
                  tooltip: '新建收藏夹',
                )
              : const SizedBox.shrink()),
          IconButton(
            onPressed: () => Get.toNamed(
                '/favSearch?searchType=1&mediaId=${_favController.favFolderData.value.list!.first.id}'),
            icon: const Icon(Icons.search_outlined),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _favController.hasMore.value = true;
          _favController.currentPage = 1;
          setState(() {
            _futureBuilderFuture = _favController.queryFavFolder(type: 'init');
          });
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder(
      future: _futureBuilderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Map? data = snapshot.data;
          if (data != null && data['status']) {
            return Obx(
              () => ListView.builder(
                controller: scrollController,
                itemCount: _favController.favFolderList.length,
                itemBuilder: (context, index) {
                  return FavItem(
                    favFolderItem: _favController.favFolderList[index],
                    isOwner: _favController.isOwner.value,
                  );
                },
              ),
            );
          } else {
            return CustomScrollView(
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                HttpError(
                  errMsg: data?['msg'] ?? '请求异常',
                  btnText: data?['code'] == -101 ? '去登录' : null,
                  fn: () {
                    if (data?['code'] == -101) {
                      RoutePush.loginRedirectPush();
                    } else {
                      setState(() {
                        _futureBuilderFuture = _favController.queryFavFolder();
                      });
                    }
                  },
                ),
              ],
            );
          }
        } else {
          // 骨架屏
          return ListView.builder(
            itemBuilder: (context, index) {
              return const VideoCardHSkeleton();
            },
            itemCount: 10,
          );
        }
      },
    );
  }
}
