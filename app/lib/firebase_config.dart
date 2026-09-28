import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Identificação do projeto Firebase do PasseiDireito (passeidireito-44b7e).
///
/// Estes valores não são segredo: só dizem QUAL projeto usar. Quem protege os
/// dados são as regras do Firestore (firestore.rules na raiz do repositório),
/// que só deixam cada conta ler e gravar o próprio progresso.
///
/// O app Android é configurado por aqui, e não pelo google-services.json, para
/// as duas plataformas lerem a configuração do mesmo lugar.
FirebaseOptions? opcoesFirebase() {
  const comum = (
    apiKey: 'AIzaSyC44nYc4TAlYu1qK35qGY-EsCANpzia3xk',
    projectId: 'passeidireito-44b7e',
    messagingSenderId: '771588164997',
    storageBucket: 'passeidireito-44b7e.firebasestorage.app',
  );

  if (kIsWeb) {
    return FirebaseOptions(
      apiKey: comum.apiKey,
      appId: '1:771588164997:web:9f8f41b5f6ba5756b188ec',
      messagingSenderId: comum.messagingSenderId,
      projectId: comum.projectId,
      authDomain: 'passeidireito-44b7e.firebaseapp.com',
      storageBucket: comum.storageBucket,
    );
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return FirebaseOptions(
      apiKey: comum.apiKey,
      appId: '1:771588164997:android:84229609cf31ae3fb188ec',
      messagingSenderId: comum.messagingSenderId,
      projectId: comum.projectId,
      storageBucket: comum.storageBucket,
    );
  }
  // iOS está fora do escopo: sem configuração, o app cai no modo de demonstração.
  return null;
}
