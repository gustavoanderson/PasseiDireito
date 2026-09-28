import 'package:flutter/material.dart';

import 'logo.dart';
import 'tema.dart';

/// Entrada com e-mail e senha. A conta da Flávia é criada no console do
/// Firebase; por isso não há tela de cadastro.
class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key, required this.entrar, required this.recuperarSenha});

  /// Lança exceção com mensagem legível quando não consegue entrar.
  final Future<void> Function(String email, String senha) entrar;
  final Future<void> Function(String email) recuperarSenha;

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocupado = false;
  String? _mensagem;
  bool _mensagemEhErro = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao, {String? sucesso}) async {
    setState(() {
      _ocupado = true;
      _mensagem = null;
    });
    try {
      await acao();
      if (sucesso != null) {
        _mensagem = sucesso;
        _mensagemEhErro = false;
      }
    } catch (e) {
      _mensagem = '$e';
      _mensagemEhErro = true;
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final cores = Cores.de(context);
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: LogoPasseiDireito(tamanho: 120)),
                    const SizedBox(height: 16),
                    Text(
                      'PasseiDireito',
                      style: TextStyle(fontFamily: fonteTitulo, fontSize: 30, fontWeight: FontWeight.w600, color: esquema.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Procurador do Município de Curitiba · Edital 6/2026',
                      style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      key: const Key('campo-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('campo-senha'),
                      controller: _senha,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                      onSubmitted: (_) => _executar(() => widget.entrar(_email.text.trim(), _senha.text)),
                    ),
                    if (_mensagem != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _mensagem!,
                        key: const Key('mensagem-login'),
                        style: TextStyle(fontSize: 14, color: _mensagemEhErro ? cores.erroTexto : cores.acertoTexto),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const Key('botao-entrar'),
                      onPressed: _ocupado ? null : () => _executar(() => widget.entrar(_email.text.trim(), _senha.text)),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: forma),
                      child: const Text('Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('botao-esqueci'),
                      onPressed: _ocupado
                          ? null
                          : () => _executar(
                                () => widget.recuperarSenha(_email.text.trim()),
                                sucesso: 'Enviamos um e-mail para redefinir a senha.',
                              ),
                      child: const Text('Esqueci minha senha'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
