// =============================================================================
// MAIN.DART - Ponto de Entrada do Aplicativo
// =============================================================================
// Este é o primeiro arquivo executado quando o aplicativo inicia.
// Ele configura o tema, inicializa serviços e define a tela inicial.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/home_screen.dart';
/// Função principal - ponto de entrada do aplicativo.
/// 
/// Esta função é chamada automaticamente pelo sistema quando o app inicia.
/// O `async` permite que façamos operações assíncronas antes de iniciar a UI.
void main() async {

  // ---------------------------------------------------------------------------
  // INICIALIZAÇÃO DO FLUTTER
  // ---------------------------------------------------------------------------
  
  // Garante que o Flutter está inicializado antes de usar plugins.
  // Necessário quando fazemos operações assíncronas antes de runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // CONFIGURAÇÃO DA ORIENTAÇÃO
  // ---------------------------------------------------------------------------
  
  // Define que o app só pode ser usado em modo retrato (vertical).
  // Isso evita problemas de layout em telas rotacionadas.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ---------------------------------------------------------------------------
  // CONFIGURAÇÃO DA BARRA DE STATUS
  // ---------------------------------------------------------------------------
  
  // Configura a aparência da barra de status do sistema.
  // Usamos ícones claros porque o app tem tema escuro.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ---------------------------------------------------------------------------
  // INICIALIZAÇÃO DO APP
  // ---------------------------------------------------------------------------
  
  // runApp() é a função que realmente inicia a interface do Flutter.
  // Passamos o widget raiz (BrainLinkApp) como parâmetro.
  runApp(const BrainLinkApp());
}

/// Widget raiz do aplicativo.
/// 
/// Este widget configura o MaterialApp, que é o container principal
/// que fornece navegação, temas e outras funcionalidades do Material Design.
class BrainLinkApp extends StatelessWidget {
  /// Construtor constante para otimização de performance.
  const BrainLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // -----------------------------------------------------------------------
      // METADADOS DO APP
      // -----------------------------------------------------------------------
      
      /// Título do app (aparece no gerenciador de tarefas).
      title: 'ALLAN VIADO',
      
      /// Remove o banner "DEBUG" do canto superior direito.
      debugShowCheckedModeBanner: false,

      // -----------------------------------------------------------------------
      // CONFIGURAÇÃO DO TEMA
      // -----------------------------------------------------------------------
      
      /// Define o tema escuro como padrão.
      themeMode: ThemeMode.dark,
      
      /// Configuração detalhada do tema escuro.
      darkTheme: ThemeData(
        // Usa Material Design 3 (mais moderno)
        useMaterial3: true,
        
        // Brilho geral do tema
        brightness: Brightness.dark,
        
        // Cor de fundo das telas
        scaffoldBackgroundColor: const Color(0xFF121212),
        
        // Esquema de cores
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          surface: const Color(0xFF1D7D02),
        ),
        
        // Configuração da AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        
        // Configuração dos Cards
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        // Configuração dos botões elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        // Configuração dos botões de texto
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
        
        // Configuração dos SnackBars
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF323232),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),

      // -----------------------------------------------------------------------
      // TELA INICIAL
      // -----------------------------------------------------------------------
      
      /// Define a HomeScreen como a tela inicial do app.
      home: const HomeScreen(),
    );
  }
}
