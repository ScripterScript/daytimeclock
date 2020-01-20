import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spritewidget/spritewidget.dart';
import 'package:flutter_clock_helper/model.dart';

import 'package:intl/intl.dart';
import 'package:digital_clock/weather.dart';

enum _Element { text }

enum _DayTime { text, shadow }

enum Background {
  morning,
  afternoon,
  evening,
}

final _lightTheme = {
  _Element.text: Colors.white,
};

final _darkTheme = {
  _Element.text: Colors.white,
};

/// A digital clock with changing daytime background
///
class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);
  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  var _temperature = '';
  var _condition = '';

  Timer _timer;
  Timer _testTimer;

  //initialize the current time
  DayTime _currentDayTime = DayTime.morning;

  Future<Null> _loadAssets(AssetBundle bundle) async {
    // Load all necessary resources
    images = new ImageMap(bundle);
    await images.load(<String>[
      'assets/clouds-0.png',
      'assets/clouds-1.png',
      'assets/clouds-2.png',
      'assets/ray.png',
      'assets/moon.png',
      'assets/sun.png',
      'assets/weathersprites.png',
      'assets/skyline_day.png',
      'assets/skyline_night.png',
    ]);

    // Load the sprite sheet, which contains snowflakes and rain drops.
    String json = await DefaultAssetBundle.of(context)
        .loadString('assets/weathersprites.json');
    sprites = new SpriteSheet(images['assets/weathersprites.png'], json);
  }

  @override
  void initState() {
    super.initState();
    // put device in landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    // Get our root asset bundle
    AssetBundle bundle = rootBundle;

    _loadAssets(bundle).then((_) {
      setState(() {
        _updateCurrentDayTime();
        weatherWorld = new WeatherWorld(_currentDayTime);
        assetsLoaded = true;
      });
    });

    widget.model.addListener(_updateModel);
    hour =
        DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_dateTime);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _testTimer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _condition = widget.model.weatherString;

      //get input of the select fields
      if (weatherWorld != null) {
        switch (_condition) {
          case "cloudy":
            weatherWorld.weatherType = WeatherType.cloudy;
            break;

          case "foggy":
            weatherWorld.weatherType = WeatherType.foggy;
            break;

          case "rainy":
            weatherWorld.weatherType = WeatherType.rain;
            break;

          case "snowy":
            weatherWorld.weatherType = WeatherType.snow;
            break;

          case "sunny":
            weatherWorld.weatherType = WeatherType.sun;
            break;

          case "thunderstorm":
            weatherWorld.weatherType = WeatherType.thunderstorm;
            break;

          case "windy":
            weatherWorld.weatherType = WeatherType.windy;
            break;
        }
      }
    });
  }

  Background backgroundScene = Background.morning;
  void _updateCurrentDayTime() {
    String hour24h = DateFormat('HH').format(_dateTime);
    int hourNumber = int.tryParse(hour24h);

    if (hourNumber == null) {
      return;
    }

    if (hourNumber > 4 && hourNumber <= 12) {
      _currentDayTime = DayTime.morning;
      backgroundScene = Background.morning;
    }

    if (hourNumber > 12 && hourNumber <= 16) {
      _currentDayTime = DayTime.afternoon;
      backgroundScene = Background.afternoon;
    }

    if (hourNumber > 16 && hourNumber <= 24) {
      _currentDayTime = DayTime.evening;
      backgroundScene = Background.evening;
    }

    if (hourNumber >= 0 && hourNumber <= 4) {
      _currentDayTime = DayTime.evening;
      backgroundScene = Background.evening;
    }

    setState(() {
      if (weatherWorld != null) {
        weatherWorld.currentDayTime = _currentDayTime;
      }
      backgroundColor = backgroundColorList[backgroundScene.index];
    });
  }

  void _updateTime() {
    _updateCurrentDayTime();
    setState(() {
      _dateTime = DateTime.now();

      _timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  //init color
  Color backgroundColor = backgroundColorList[0];
  bool assetsLoaded = false;
  WeatherWorld weatherWorld;
  String hour = "";

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;
    hour =
        DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_dateTime);

    final minute = DateFormat('mm').format(_dateTime);
    final ampm = DateFormat(' a').format(_dateTime);
    final fontSize = MediaQuery.of(context).size.width / 10;
    final fontSizeAMPM = MediaQuery.of(context).size.width / 15;
    final fontSizeSmall = MediaQuery.of(context).size.width / 20;
    final clockOffsetTop = MediaQuery.of(context).size.width / 80;
    final clockOffsetRight = MediaQuery.of(context).size.width / 80;
    final defaultStyle = TextStyle(
        color: colors[_DayTime.text],
        fontFamily: 'NeuchaRegular',
        fontSize: fontSize);
    final defaultStyleSmall = TextStyle(
      color: colors[_DayTime.text],
      fontFamily: 'NeuchaRegular',
      fontSize: fontSizeSmall,
    );
    final defaultStyleAMPM = TextStyle(
      color: colors[_DayTime.text],
      fontFamily: 'NeuchaRegular',
      fontSize: fontSizeAMPM,
    );
    //if the assets not loaded already
    if (!assetsLoaded) {
      return Container();
    }
    return AnimatedContainer(
        color: backgroundColor,
        curve: Curves.fastOutSlowIn,
        duration: Duration(seconds: 2),
        child: Stack(children: <Widget>[
          Positioned(
              child: Align(
                  alignment: FractionalOffset.bottomLeft,
                  child: _currentDayTime == DayTime.evening
                      ? Image.asset("assets/skyline_night.png")
                      : Image.asset("assets/skyline_day.png"))),
          Center(
            child: new SpriteWidget(weatherWorld),
          ),
          DefaultTextStyle(
            style: defaultStyle,
            child: Stack(
              children: <Widget>[
                Positioned(
                    right: clockOffsetRight,
                    top: clockOffsetTop,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(hour),
                            Text(":"),
                            Text(minute),
                            DefaultTextStyle(
                                style: defaultStyleAMPM,
                                child: (widget.model.is24HourFormat
                                    ? Text("")
                                    : Text(ampm)))
                          ],
                        ),
                        DefaultTextStyle(
                            style: defaultStyleSmall,
                            child: Text(_temperature)),
                      ],
                    ))
              ],
            ),
          ),
        ]));
  }
}
