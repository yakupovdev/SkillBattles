import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/features/auth/domain/entity/login_params_entity.dart';
import 'package:skill_battles/features/auth/domain/usecases/login_usecase.dart';
import '../helpers/app_test_harness.dart';
void main(){ testWidgets('d',(t) async{ 
 await t.runAsync(() async { final d=await AppDependencies.init(config: mockConfig);
 final r=await d.getDep<LoginUsecase>()(const LoginParamsEntity(email:'tester@example.com',password:'Password1!'));
 debugPrint('R: $r');});
});}
