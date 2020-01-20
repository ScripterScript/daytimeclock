import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';
import 'dart:ui' as ui show Image;

// The image map hold all of our image assets.
ImageMap images;

// The sprite sheet contains an image and a set of rectangles defining the
// individual sprites.
SpriteSheet sprites;

//enum for the different daytimes
enum DayTime {
  morning,
  afternoon,
  evening,
}

enum WeatherType { cloudy, foggy, rain, snow, sun, thunderstorm, windy }

//get the time of the clock
//decide the backgroundcolor of the daytimes
var backgroundColorList = [
  Color(0xFFFF8F00),
  Color(0xFF40C4FF),
  Color(0xFF1A237E)
];

class WeatherWorld extends NodeWithSize {
  WeatherWorld(DayTime dayTime) : super(const Size(2048.0, 2048.0)) {
    currentDayTime = dayTime;
    // Then three layers of clouds, that will be scrolled in parallax.

    _cloudsFoggy = new CloudLayer(
        image: images['assets/clouds-2.png'],
        rotated: false,
        dark: false,
        loopTime: 80.0);
    _cloudsFoggy.active = false;

    _cloudsSharp = new CloudLayer(
        image: images['assets/clouds-0.png'],
        rotated: false,
        dark: false,
        loopTime: 80.0);

    _cloudsDark = new CloudLayer(
        image: images['assets/clouds-1.png'],
        rotated: true,
        dark: true,
        loopTime: 40.0);

    _cloudsSoft = new CloudLayer(
        image: images['assets/clouds-1.png'],
        rotated: false,
        dark: false,
        loopTime: 60.0);

    _sun = new Sun();
    _sun.position = const Offset(1024.0, 1024.0);
    _sun.scale = 1.0;

    _moon = new Moon();
    _moon.position = const Offset(1024.0, 1024.0);
    _moon.scale = 1.0;

    if (currentDayTime == DayTime.evening) {
      _sun.active = false;
    }

    if (currentDayTime != DayTime.evening) {
      _moon.active = false;
    }
    addChild(_moon);
    addChild(_sun);
    addChild(_cloudsDark);
    addChild(_cloudsSoft);
    addChild(_cloudsFoggy);
    addChild(_cloudsSharp);

    _rain = new Rain();
    addChild(_rain);

    _snow = new Snow();
    addChild(_snow);
  }

  CloudLayer _cloudsFoggy;
  CloudLayer _cloudsSharp;
  CloudLayer _cloudsSoft;
  CloudLayer _cloudsDark;
  Sun _sun;
  Moon _moon;
  Rain _rain;
  Snow _snow;
  DayTime _currentDayTime = DayTime.morning;

  DayTime get currentDayTime => _currentDayTime;

  set currentDayTime(DayTime currentDayTime) {
    _currentDayTime = currentDayTime;

    if (_moon != null) {
      _moon.active = _currentDayTime == DayTime.evening;
    }

    if (_sun != null) {
      _sun.active = (_currentDayTime == DayTime.morning ||
          _currentDayTime == DayTime.afternoon);
    }
  }

  WeatherType get weatherType => _weatherType;

  WeatherType _weatherType = WeatherType.sun;

  set weatherType(WeatherType weatherType) {
    if (weatherType == _weatherType) return;

    // handle changes between weather types.
    _weatherType = weatherType;

    _cloudsDark.active = weatherType != WeatherType.sun;

    _rain.active = weatherType == WeatherType.rain;
    _snow.active = weatherType == WeatherType.snow;
    _cloudsFoggy.active = weatherType == WeatherType.foggy;
  }

  @override
  void spriteBoxPerformedLayout() {
    // If the device is rotated or if the size of the SpriteWidget changes we
    // are adjusting the position of the sun.
    _sun?.position = spriteBox.visibleArea.topLeft + const Offset(350.0, 180.0);
    _moon?.position =
        spriteBox.visibleArea.topLeft + const Offset(250.0, 220.0);
  }
}

// The GradientNode performs custom drawing to draw a gradient background.
class GradientNode extends NodeWithSize {
  GradientNode(Size size, this.colorTop, this.colorBottom) : super(size);

  Color colorTop;
  Color colorBottom;

  @override
  void paint(Canvas canvas) {
    applyTransformForPivot(canvas);

    Rect rect = Offset.zero & size;
    Paint gradientPaint = new Paint()
      ..shader = new LinearGradient(
          begin: FractionalOffset.topLeft,
          end: FractionalOffset.bottomLeft,
          colors: <Color>[colorTop, colorBottom],
          stops: <double>[0.0, 1.0]).createShader(rect);

    canvas.drawRect(rect, gradientPaint);
  }
}

// Draws and animates a cloud layer using two sprites.
class CloudLayer extends Node {
  CloudLayer({ui.Image image, bool dark, bool rotated, double loopTime}) {
    // Creates and positions the two cloud sprites.
    _sprites.add(_createSprite(image, dark, rotated));
    _sprites[0].position = const Offset(1024.0, 1024.0);
    addChild(_sprites[0]);

    _sprites.add(_createSprite(image, dark, rotated));
    _sprites[1].position = const Offset(3072.0, 1024.0);
    addChild(_sprites[1]);

    // Animates the clouds across the screen.
    motions.run(new MotionRepeatForever(new MotionTween<Offset>(
        (a) => position = a,
        Offset.zero,
        const Offset(-2048.0, 0.0),
        loopTime)));
  }

  List<Sprite> _sprites = <Sprite>[];

  Sprite _createSprite(ui.Image image, bool dark, bool rotated) {
    Sprite sprite = new Sprite.fromImage(image);

    if (rotated) sprite.scaleX = -1.0;

    if (dark) {
      sprite.colorOverlay = const Color(0xff000000);
      sprite.opacity = 0.0;
    }

    return sprite;
  }

  set active(bool active) {
    // Toggle visibility of the cloud layer
    double opacity;
    if (active)
      opacity = 1.0;
    else
      opacity = 0.0;

    for (Sprite sprite in _sprites) {
      sprite.motions.stopAll();
      sprite.motions.run(new MotionTween<double>(
          (a) => sprite.opacity = a, sprite.opacity, opacity, 1.0));
    }
  }
}

const double _kNumSunRays = 50.0;

class Moon extends Node {
  Moon() {
    // Create the moon
    _moon = new Sprite.fromImage(images['assets/moon.png']);
    _moon.scale = 4.0;
    _moon.transferMode = BlendMode.plus;
    addChild(_moon);
  }

  Sprite _moon;

  set active(bool active) {
    // Toggle visibility of the sun

    motions.stopAll();

    double targetOpacity;
    if (!active)
      targetOpacity = 0.0;
    else
      targetOpacity = 1.0;

    motions.run(new MotionTween<double>(
        (a) => _moon.opacity = a, _moon.opacity, targetOpacity, 2.0));
  }
}

// Create an animated sun with rays
class Sun extends Node {
  Sun() {
    // Create the sun
    _sun = new Sprite.fromImage(images['assets/sun.png']);
    _sun.scale = 4.0;
    _sun.transferMode = BlendMode.plus;
    addChild(_sun);

    // Create rays
    _rays = <Ray>[];
    for (int i = 0; i < _kNumSunRays; i += 1) {
      Ray ray = new Ray();
      addChild(ray);
      _rays.add(ray);
    }
  }

  Sprite _sun;
  List<Ray> _rays;

  set active(bool active) {
    // Toggle visibility of the sun

    motions.stopAll();

    double targetOpacity;
    if (!active)
      targetOpacity = 0.0;
    else
      targetOpacity = 1.0;

    motions.run(new MotionTween<double>(
        (a) => _sun.opacity = a, _sun.opacity, targetOpacity, 2.0));

    if (active) {
      for (Ray ray in _rays) {
        motions.run(new MotionSequence(<Motion>[
          new MotionDelay(1.5),
          new MotionTween<double>(
              (a) => ray.opacity = a, ray.opacity, ray.maxOpacity, 1.5)
        ]));
      }
    } else {
      for (Ray ray in _rays) {
        motions.run(new MotionTween<double>(
            (a) => ray.opacity = a, ray.opacity, 0.0, 0.2));
      }
    }
  }
}

// An animated sun ray
class Ray extends Sprite {
  double _rotationSpeed;
  double maxOpacity;

  Ray() : super.fromImage(images['assets/ray.png']) {
    pivot = const Offset(0.0, 0.5);
    transferMode = BlendMode.plus;
    rotation = randomDouble() * 360.0;
    maxOpacity = randomDouble() * 0.2;
    opacity = maxOpacity;
    scaleX = 2.5 + randomDouble();
    scaleY = 0.3;
    _rotationSpeed = randomSignedDouble() * 2.0;

    // Scale animation
    double scaleTime = randomSignedDouble() * 2.0 + 4.0;

    motions.run(new MotionRepeatForever(new MotionSequence(<Motion>[
      new MotionTween<double>(
          (a) => scaleX = a, scaleX, scaleX * 0.5, scaleTime),
      new MotionTween<double>(
          (a) => scaleX = a, scaleX * 0.5, scaleX, scaleTime)
    ])));
  }

  @override
  void update(double dt) {
    rotation += dt * _rotationSpeed;
  }
}

// Rain layer. Uses three layers of particle systems, to create a parallax
// rain effect.
class Rain extends Node {
  Rain() {
    _addParticles(1.0);
    _addParticles(1.5);
    _addParticles(2.0);
  }

  List<ParticleSystem> _particles = <ParticleSystem>[];

  void _addParticles(double distance) {
    ParticleSystem particles = new ParticleSystem(sprites['raindrop.png'],
        transferMode: BlendMode.srcATop,
        posVar: const Offset(1400.0, 0.0),
        direction: 90.0,
        directionVar: 0.0,
        speed: 1500.0 / distance,
        speedVar: 100.0 / distance,
        startSize: 1.2 / distance,
        startSizeVar: 0.2 / distance,
        endSize: 1.2 / distance,
        endSizeVar: 0.2 / distance,
        life: 1.5 * distance,
        lifeVar: 1.0 * distance);
    particles.position = const Offset(1024.0, -200.0);
    particles.rotation = 10.0;
    particles.opacity = 0.0;

    _particles.add(particles);
    addChild(particles);
  }

  set active(bool active) {
    motions.stopAll();
    for (ParticleSystem system in _particles) {
      if (active) {
        motions.run(new MotionTween<double>(
            (a) => system.opacity = a, system.opacity, 1.0, 2.0));
      } else {
        motions.run(new MotionTween<double>(
            (a) => system.opacity = a, system.opacity, 0.0, 0.5));
      }
    }
  }
}

// Snow. Uses 9 particle systems to create a parallax effect of snow at
// different distances.
class Snow extends Node {
  Snow() {
    _addParticles(sprites['flake-0.png'], 1.0);
    _addParticles(sprites['flake-1.png'], 1.0);
    _addParticles(sprites['flake-2.png'], 1.0);

    _addParticles(sprites['flake-3.png'], 1.5);
    _addParticles(sprites['flake-4.png'], 1.5);
    _addParticles(sprites['flake-5.png'], 1.5);

    _addParticles(sprites['flake-6.png'], 2.0);
    _addParticles(sprites['flake-7.png'], 2.0);
    _addParticles(sprites['flake-8.png'], 2.0);
  }

  List<ParticleSystem> _particles = <ParticleSystem>[];

  void _addParticles(SpriteTexture texture, double distance) {
    ParticleSystem particles = new ParticleSystem(texture,
        transferMode: BlendMode.srcATop,
        posVar: const Offset(1300.0, 0.0),
        direction: 90.0,
        directionVar: 0.0,
        speed: 150.0 / distance,
        speedVar: 50.0 / distance,
        startSize: 1.0 / distance,
        startSizeVar: 0.3 / distance,
        endSize: 1.2 / distance,
        endSizeVar: 0.2 / distance,
        life: 20.0 * distance,
        lifeVar: 10.0 * distance,
        emissionRate: 2.0,
        startRotationVar: 360.0,
        endRotationVar: 360.0,
        radialAccelerationVar: 10.0 / distance,
        tangentialAccelerationVar: 10.0 / distance);
    particles.position = const Offset(1024.0, -200.0);
    particles.opacity = 0.0;

    _particles.add(particles);
    addChild(particles);
  }

  set active(bool active) {
    motions.stopAll();
    for (ParticleSystem system in _particles) {
      if (active) {
        motions.run(new MotionTween<double>(
            (a) => system.opacity = a, system.opacity, 1.0, 2.0));
      } else {
        motions.run(new MotionTween<double>(
            (a) => system.opacity = a, system.opacity, 0.0, 0.5));
      }
    }
  }
}
