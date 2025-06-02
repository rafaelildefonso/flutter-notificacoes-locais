import 'package:flutter/widgets.dart';
import 'package:notificacoes_locais/noti_service.dart';

class AppLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // O aplicativo está sendo pausado. Isso geralmente significa que ele está indo para o segundo plano
      // ou sendo fechado.
      print('AppLifecycleState: pausado (App going to background or being closed)');
      _executarFuncaoQuandoFechar();
    } else if (state == AppLifecycleState.detached) {
      // A árvore de visualização do aplicativo foi completamente removida.
      // Isso é o mais próximo que você chega de um "fechamento" garantido em alguns cenários.
      print('AppLifecycleState: detached (App completely removed)');
      _executarFuncaoQuandoFechar();
    }
    // Você pode lidar com outros estados aqui, se necessário:
    // AppLifecycleState.resumed: Aplicativo está ativo e visível.
    // AppLifecycleState.inactive: Aplicativo está em um estado transitório (ex: chamada telefônica).
    // AppLifecycleState.hidden: Aplicativo está oculto da vista. (Adicionado no Flutter 3.13)
  }

  void _executarFuncaoQuandoFechar() {
    print('Executando função quando o app está sendo fechado!');
    NotificationService().showNotification("Brava demais", "Volta pro app só");
    NotificationService().zonedScheduleNotification();
    // Coloque seu código aqui que deve ser executado quando o app fechar.
    // CUIDADO: Operações longas ou que exigem UI podem não funcionar bem aqui.
    // Pense em salvar dados, liberar recursos, etc.
  }
}