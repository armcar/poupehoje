import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  final tips = [
    {
      'icon': '💡',
      'text': 'Reserve 10% do rendimento mensal para poupança.',
      'category': 'geral'
    },
    {
      'icon': '📅',
      'text': 'Defina um orçamento semanal e siga-o com disciplina.',
      'category': 'geral'
    },
    {
      'icon': '🧾',
      'text': 'Anote todas as despesas, mesmo as pequenas — elas somam-se.',
      'category': 'geral'
    },
    {
      'icon': '💰',
      'text':
          'Pague-se a si próprio primeiro — trate a poupança como uma despesa fixa.',
      'category': 'geral'
    },
    {
      'icon': '📉',
      'text': 'Corte despesas que não trazem valor real à sua vida.',
      'category': 'geral'
    },
    {
      'icon': '📦',
      'text': 'Evite compras por impulso — espere 24h antes de decidir.',
      'category': 'geral'
    },
    {
      'icon': '🔄',
      'text': 'Reutilize o que já tem antes de comprar algo novo.',
      'category': 'geral'
    },
    {
      'icon': '📚',
      'text': 'Invista em conhecimento financeiro — é o melhor retorno.',
      'category': 'geral'
    },
    {
      'icon': '💧',
      'text':
          'Feche a torneira enquanto escova os dentes — pequenas poupanças somam.',
      'category': 'casa'
    },
    {
      'icon': '💡',
      'text':
          'Substitua lâmpadas tradicionais por LED — reduza até 80% na energia.',
      'category': 'casa'
    },
    {
      'icon': '🧺',
      'text': 'Lave roupa apenas com carga completa na máquina.',
      'category': 'casa'
    },
    {
      'icon': '🌡️',
      'text':
          'Desligue aparelhos da tomada — o “standby” também consome energia.',
      'category': 'casa'
    },
    {
      'icon': '🧼',
      'text': 'Use produtos de limpeza multiusos para gastar menos.',
      'category': 'casa'
    },
    {
      'icon': '🍲',
      'text': 'Cozinhe em casa — é mais saudável e barato que comer fora.',
      'category': 'casa'
    },
    {
      'icon': '🍞',
      'text': 'Planeie refeições semanais e evite o desperdício alimentar.',
      'category': 'casa'
    },
    {
      'icon': '🥶',
      'text':
          'Ajuste o frigorífico para 5 °C — mais frio só gasta energia à toa.',
      'category': 'casa'
    },
    {
      'icon': '🚶‍♀️',
      'text': 'Caminhe ou use bicicleta em pequenas distâncias.',
      'category': 'transporte'
    },
    {
      'icon': '🚗',
      'text': 'Partilhe boleias — o combustível é uma das maiores despesas.',
      'category': 'transporte'
    },
    {
      'icon': '🚌',
      'text': 'Use transportes públicos sempre que possível.',
      'category': 'transporte'
    },
    {
      'icon': '⛽',
      'text':
          'Mantenha os pneus calibrados — o carro consome menos combustível.',
      'category': 'transporte'
    },
    {
      'icon': '🛞',
      'text':
          'Evite arranques e travagens bruscas — poupa combustível e travões.',
      'category': 'transporte'
    },
    {
      'icon': '📱',
      'text': 'Desinstale apps que incentivam gastos desnecessários.',
      'category': 'financeiro'
    },
    {
      'icon': '💳',
      'text': 'Evite cartões de crédito para compras pequenas.',
      'category': 'financeiro'
    },
    {
      'icon': '💸',
      'text': 'Negocie tarifas de internet e telecomunicações anualmente.',
      'category': 'financeiro'
    },
    {
      'icon': '🛍️',
      'text': 'Procure descontos e cashback antes de comprar online.',
      'category': 'financeiro'
    },
    {
      'icon': '💼',
      'text':
          'Automatize as poupanças — um débito automático para uma conta separada.',
      'category': 'financeiro'
    },
    {
      'icon': '🏦',
      'text':
          'Revise comissões bancárias — pode estar a pagar por serviços que não usa.',
      'category': 'financeiro'
    },
    {
      'icon': '☕',
      'text': 'Use garrafa reutilizável — evita comprar bebidas fora.',
      'category': 'ecológico'
    },
    {
      'icon': '🛍️',
      'text': 'Leve sacos reutilizáveis para o supermercado.',
      'category': 'ecológico'
    },
    {
      'icon': '🌍',
      'text': 'Recicle e venda materiais — pequenas receitas extra ajudam.',
      'category': 'ecológico'
    },
  ];

  for (final tip in tips) {
    await firestore.collection('tips').add(tip);
  }

  debugPrint(
      '✅ Dicas carregadas com sucesso no Firestore (${tips.length} docs).');
}
