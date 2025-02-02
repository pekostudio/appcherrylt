import 'package:flutter/material.dart';

class CustomSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
  });

  @override
  CustomSwitchState createState() => CustomSwitchState();
}

class CustomSwitchState extends State<CustomSwitch> {
  bool _value = false;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  void _toggleSwitch() {
    setState(() {
      _value = !_value;
      widget.onChanged(_value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleSwitch,
      child: Container(
        width: 58,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: _value ? widget.activeColor : widget.inactiveColor,
          border:
              Border.all(color: const Color.fromARGB(255, 0, 0, 0), width: 1),
        ),
        child: Stack(
          children: [
            Align(
              alignment: _value ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.fromLTRB(4.0, 2.0, 4.0, 2.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 96, 96, 96),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Align(
              alignment: _value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  _value ? "Online" : "Offline",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 45, 45, 45),
                    fontWeight: FontWeight.bold,
                    fontSize: 11.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
