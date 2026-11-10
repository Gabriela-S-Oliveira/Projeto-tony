import 'package:flutter/material.dart';

void main() => runApp(const ControleGastosApp());

// Paleta: rosa, roxo e off-white
class Cores {
  static const rosa = Color(0xFFE85D9A);
  static const rosaClaro = Color(0xFFF9D3E4);
  static const roxo = Color(0xFF6B3FA0);
  static const roxoEscuro = Color(0xFF3E2163);
  static const offWhite = Color(0xFFFAF7F2);
}

class Gasto {
  final String descricao;
  final double valor;
  final DateTime data;
  final String categoria;
  Gasto(this.descricao, this.valor, this.data, this.categoria);
}

const categorias = ['Alimentação', 'Transporte', 'Casa', 'Lazer', 'Saúde', 'Outros'];
const meses = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];

String real(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

class ControleGastosApp extends StatelessWidget {
  const ControleGastosApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Gastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Cores.offWhite,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Cores.roxo, primary: Cores.roxo, secondary: Cores.rosa, surface: Cores.offWhite),
        appBarTheme: const AppBarTheme(backgroundColor: Cores.roxo, foregroundColor: Cores.offWhite),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int aba = 0;
  double renda = 3000;
  double reservaMinima = 0.10; // 10% guardado para emergências
  DateTime mesAtual = DateTime(DateTime.now().year, DateTime.now().month);
  final List<Gasto> gastos = [];

  List<Gasto> get gastosDoMes => gastos
      .where((g) => g.data.year == mesAtual.year && g.data.month == mesAtual.month)
      .toList();
  double get totalMes => gastosDoMes.fold(0, (s, g) => s + g.valor);
  double get sobra => renda - totalMes;
  double get podeInvestir {
    final v = sobra - renda * reservaMinima;
    return v > 0 ? v : 0;
  }

  void mudarMes(int d) => setState(() => mesAtual = DateTime(mesAtual.year, mesAtual.month + d));

  Future<void> adicionarGasto([DateTime? dia]) async {
    final desc = TextEditingController();
    final valor = TextEditingController();
    String cat = categorias.first;
    DateTime data = dia ?? DateTime.now();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Cores.offWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Novo gasto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Cores.roxoEscuro)),
            const SizedBox(height: 12),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'Descrição')),
            TextField(controller: valor, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor (R\$)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: cat,
              items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => set(() => cat = v!),
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today, color: Cores.rosa),
              label: Text('${data.day}/${data.month}/${data.year}'),
              onPressed: () async {
                final p = await showDatePicker(context: ctx, initialDate: data, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (p != null) set(() => data = p);
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Cores.rosa, padding: const EdgeInsets.all(14)),
              onPressed: () {
                final v = double.tryParse(valor.text.replaceAll(',', '.'));
                if (v == null || v <= 0 || desc.text.trim().isEmpty) return;
                setState(() => gastos.add(Gasto(desc.text.trim(), v, data, cat)));
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ]),
        );
      }),
    );
  }

  Future<void> editarRenda() async {
    final c = TextEditingController(text: renda.toStringAsFixed(2));
    final r = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Cores.offWhite,
        title: const Text('Renda mensal'),
        content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: 'R\$ ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, double.tryParse(c.text.replaceAll(',', '.'))), child: const Text('Salvar')),
        ],
      ),
    );
    if (r != null && r >= 0) setState(() => renda = r);
  }

  @override
  Widget build(BuildContext context) {
    final telas = [_resumo(), _calendario()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Gastos', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.account_balance_wallet), onPressed: editarRenda, tooltip: 'Renda')],
      ),
      body: Column(children: [_seletorMes(), Expanded(child: telas[aba])]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Cores.rosa, foregroundColor: Cores.offWhite,
        onPressed: () => adicionarGasto(), child: const Icon(Icons.add)),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Cores.rosaClaro,
        indicatorColor: Cores.rosa.withValues(alpha: 0.35),
        selectedIndex: aba,
        onDestinationSelected: (i) => setState(() => aba = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), label: 'Resumo'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendário'),
        ],
      ),
    );
  }

  Widget _seletorMes() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.chevron_left, color: Cores.roxo), onPressed: () => mudarMes(-1)),
          Text('${meses[mesAtual.month - 1]} ${mesAtual.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Cores.roxoEscuro)),
          IconButton(icon: const Icon(Icons.chevron_right, color: Cores.roxo), onPressed: () => mudarMes(1)),
        ]),
      );

  Widget _cartaoInvestimento() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Cores.roxo, Cores.rosa]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Você pode investir este mês', style: TextStyle(color: Cores.offWhite)),
          const SizedBox(height: 6),
          Text(real(podeInvestir), style: const TextStyle(color: Cores.offWhite, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            _mini('Renda', real(renda)),
            _mini('Gastos', real(totalMes)),
            _mini('Reserva ${(reservaMinima * 100).round()}%', real(renda * reservaMinima)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: renda == 0 ? 0 : (totalMes / renda).clamp(0, 1),
              minHeight: 8, backgroundColor: Cores.offWhite.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Cores.offWhite)),
          ),
          if (sobra < 0)
            const Padding(padding: EdgeInsets.only(top: 8),
                child: Text('Atenção: gastos acima da renda!', style: TextStyle(color: Cores.offWhite, fontWeight: FontWeight.bold))),
        ]),
      );

  Widget _mini(String t, String v) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: TextStyle(color: Cores.offWhite.withValues(alpha: 0.8), fontSize: 12)),
          Text(v, style: const TextStyle(color: Cores.offWhite, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _resumo() {
    final lista = gastosDoMes..sort((a, b) => b.data.compareTo(a.data));
    final porCat = <String, double>{};
    for (final g in lista) {
      porCat[g.categoria] = (porCat[g.categoria] ?? 0) + g.valor;
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      _cartaoInvestimento(),
      const SizedBox(height: 20),
      if (porCat.isNotEmpty) ...[
        const Text('Por categoria', style: TextStyle(fontWeight: FontWeight.bold, color: Cores.roxoEscuro, fontSize: 16)),
        ...porCat.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(width: 100, child: Text(e.key)),
                Expanded(child: LinearProgressIndicator(value: e.value / totalMes, color: Cores.rosa, backgroundColor: Cores.rosaClaro, minHeight: 8)),
                const SizedBox(width: 8),
                Text(real(e.value)),
              ]),
            )),
        const SizedBox(height: 20),
      ],
      const Text('Gastos do mês', style: TextStyle(fontWeight: FontWeight.bold, color: Cores.roxoEscuro, fontSize: 16)),
      if (lista.isEmpty)
        const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nenhum gasto ainda. Toque no + para adicionar.'))),
      ...lista.map(_itemGasto),
    ]);
  }

  Widget _itemGasto(Gasto g) => Card(
        color: Colors.white,
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Cores.rosaClaro, child: Icon(Icons.receipt_long, color: Cores.roxo)),
          title: Text(g.descricao),
          subtitle: Text('${g.categoria} • ${g.data.day}/${g.data.month}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(real(g.valor), style: const TextStyle(fontWeight: FontWeight.bold, color: Cores.roxo)),
            IconButton(icon: const Icon(Icons.delete_outline, color: Cores.rosa), onPressed: () => setState(() => gastos.remove(g))),
          ]),
        ),
      );

  Widget _calendario() {
    final diasNoMes = DateTime(mesAtual.year, mesAtual.month + 1, 0).day;
    final offset = DateTime(mesAtual.year, mesAtual.month, 1).weekday % 7; // domingo = 0
    final totais = <int, double>{};
    for (final g in gastosDoMes) {
      totais[g.data.day] = (totais[g.data.day] ?? 0) + g.valor;
    }
    final maior = totais.values.fold<double>(0, (m, v) => v > m ? v : m);
    const sem = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    return ListView(padding: const EdgeInsets.all(16), children: [
      _cartaoInvestimento(),
      const SizedBox(height: 16),
      Row(children: sem.map((d) => Expanded(child: Center(
          child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, color: Cores.roxo))))).toList()),
      const SizedBox(height: 6),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 0.8),
        itemCount: offset + diasNoMes,
        itemBuilder: (_, i) {
          if (i < offset) return const SizedBox();
          final dia = i - offset + 1;
          final t = totais[dia] ?? 0;
          final intensidade = maior == 0 ? 0.0 : t / maior;
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _detalheDia(dia),
            onLongPress: () => adicionarGasto(DateTime(mesAtual.year, mesAtual.month, dia)),
            child: Container(
              decoration: BoxDecoration(
                color: t == 0 ? Colors.white : Color.lerp(Cores.rosaClaro, Cores.rosa, intensidade),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Cores.rosaClaro),
              ),
              padding: const EdgeInsets.all(4),
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('$dia', style: TextStyle(fontWeight: FontWeight.bold,
                    color: intensidade > 0.6 ? Cores.offWhite : Cores.roxoEscuro)),
                if (t > 0)
                  FittedBox(child: Text(t.toStringAsFixed(0),
                      style: TextStyle(fontSize: 11, color: intensidade > 0.6 ? Cores.offWhite : Cores.roxo))),
              ]),
            ),
          );
        },
      ),
      const SizedBox(height: 8),
      const Text('Toque num dia para ver os gastos • segure para adicionar',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Cores.roxo)),
    ]);
  }

  void _detalheDia(int dia) {
    final lista = gastosDoMes.where((g) => g.data.day == dia).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Cores.offWhite,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('$dia de ${meses[mesAtual.month - 1]}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Cores.roxoEscuro)),
          if (lista.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Sem gastos neste dia.')),
          ...lista.map((g) => ListTile(title: Text(g.descricao), subtitle: Text(g.categoria), trailing: Text(real(g.valor)))),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Cores.rosa),
            icon: const Icon(Icons.add), label: const Text('Adicionar gasto neste dia'),
            onPressed: () { Navigator.pop(ctx); adicionarGasto(DateTime(mesAtual.year, mesAtual.month, dia)); },
          ),
        ]),
      ),
    );
  }
}
