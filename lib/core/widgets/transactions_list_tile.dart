import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class TransactionsListTile extends StatelessWidget {
  const TransactionsListTile({super.key});

  @override
  Widget build(BuildContext context) {
    dynamic data;
    final credit = switch (data?.credit) {
      String creditValue when creditValue.isNotEmpty => true,
      _ => false,
    };
    final formatter = DateFormat('dd/MM/yyyy');
    final date = formatter.format(DateTime.parse(data?.transactionDate ?? DateTime.now().toString()));

    final indexAmount = (data?.amount ?? 0).toInt();
    final amount = indexAmount.toString();

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () {},
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: credit ? Colors.green.withValues(alpha: 0.04) : Colors.red.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Transform.rotate(
            angle: 10,
            child: Icon(
              credit ? Iconsax.arrow_up : Iconsax.arrow_down_1,
              color: credit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                data?.narration?.toLowerCase().capitalize() ?? '---',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        subtitle: Container(
          margin: EdgeInsets.only(top: 5),
          child: Text(date, style: TextStyle(fontSize: 12)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 15,
          children: [
            Text(
              credit ? "+ ₦ $amount" : "- ₦ $amount",
              style: TextStyle(fontWeight: FontWeight.w500, color: credit ? Colors.green : Colors.red),
            ),
            Icon(Iconsax.arrow_right_3, color: Colors.black, size: 15),
          ],
        ),
      ),
    );
  }
}
