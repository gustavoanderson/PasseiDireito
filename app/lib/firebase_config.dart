import 'package:firebase_core/firebase_core.dart';

/// Identificação do projeto Firebase do PasseiDireito.
///
/// Enquanto devolver null, o app roda em modo de demonstração, sem salvar
/// progresso, e avisa isso na tela.
///
/// Estes valores não são segredo: só dizem QUAL projeto usar. Quem protege os
/// dados são as regras do Firestore (firestore.rules na raiz do repositório),
/// que só deixam cada conta ler e gravar o próprio progresso.
FirebaseOptions? opcoesFirebase() => null;
