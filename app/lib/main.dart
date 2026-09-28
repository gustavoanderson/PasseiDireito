import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'banco.dart';
import 'firebase_config.dart';
import 'progresso.dart';
import 'progresso_firestore.dart';
import 'tela_inicio.dart';
import 'tela_login.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sem configuração, ou se o Firebase falhar ao iniciar, o app abre mesmo
  // assim em modo de demonstração. Tela preta puniria quem não tem culpa.
  var firebaseLigado = false;
  final opcoes = opcoesFirebase();
  if (opcoes != null) {
    try {
      await Firebase.initializeApp(options: opcoes);
      // Na web o cache offline precisa ser pedido; no Android já vem ligado.
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
      firebaseLigado = true;
    } catch (_) {}
  }

  runApp(PasseiDireito(inicio: firebaseLigado ? const _PortaoDeLogin() : null));
}

class PasseiDireito extends StatefulWidget {
  const PasseiDireito({super.key, this.inicio, this.carregar = carregarUnidades});

  /// A primeira tela. Null = modo de demonstração, com progresso só em memória.
  final Widget? inicio;

  /// Trocável nos testes, para não depender da leitura do banco real.
  final Future<List<Unidade>> Function() carregar;

  @override
  State<PasseiDireito> createState() => _PasseiDireitoState();
}

class _PasseiDireitoState extends State<PasseiDireito> {
  // Segue o celular até ela tocar no botão de lua/sol; daí em diante vale a escolha dela.
  ThemeMode _modo = ThemeMode.system;
  final _progressoDemonstracao = ProgressoEmMemoria();

  void _alternar(Brightness atual) {
    setState(() => _modo = atual == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return ControleTema(
      alternar: _alternar,
      child: MaterialApp(
        title: 'PasseiDireito',
        theme: temaClaro(),
        darkTheme: temaEscuro(),
        themeMode: _modo,
        home: widget.inicio ??
            TelaInicio(
              registro: _progressoDemonstracao,
              carregar: widget.carregar,
              progressoSalvo: false,
            ),
      ),
    );
  }
}

/// Com o Firebase ligado: sem login, tela de entrada; com login, as trilhas
/// gravando no Firestore da conta dela.
class _PortaoDeLogin extends StatelessWidget {
  const _PortaoDeLogin();

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, estado) {
        if (estado.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final usuaria = estado.data;
        if (usuaria == null) {
          return TelaLogin(
            entrar: (email, senha) => _traduzir(() => auth.signInWithEmailAndPassword(email: email, password: senha)),
            recuperarSenha: (email) => _traduzir(() => auth.sendPasswordResetEmail(email: email)),
          );
        }
        return TelaInicio(
          key: ValueKey(usuaria.uid),
          registro: ProgressoFirestore(FirebaseFirestore.instance, usuaria.uid),
        );
      },
    );
  }

  /// Troca os códigos de erro do Firebase por frases que ela entenda.
  static Future<void> _traduzir(Future<Object?> Function() acao) async {
    try {
      await acao();
    } on FirebaseAuthException catch (e) {
      throw switch (e.code) {
        'invalid-email' => 'O e-mail está em formato inválido.',
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'E-mail ou senha incorretos.',
        'too-many-requests' => 'Muitas tentativas seguidas. Espere alguns minutos e tente de novo.',
        'network-request-failed' => 'Sem conexão com a internet. O primeiro acesso precisa de rede.',
        'missing-email' => 'Digite o e-mail antes de pedir a nova senha.',
        _ => 'Não consegui entrar (${e.code}).',
      };
    }
  }
}
