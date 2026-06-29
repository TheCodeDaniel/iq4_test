import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_test/features/transactions/presentation/bloc/products_bloc.dart';
import 'package:iq_test/core/services/local_storage/product_cache_services.dart';
import 'package:iq_test/features/auth/pin_lock_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProductCacheService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => ProductsBloc())],
      child: MaterialApp(home: PinLockView(), debugShowCheckedModeBanner: false, theme: ThemeData(useMaterial3: false)),
    );
  }
}
