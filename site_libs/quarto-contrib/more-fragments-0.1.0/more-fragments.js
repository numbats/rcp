// More Fragments - Direction detection for entrance/exit animation pairs

(function() {
  // ==========================================================================
  // Letter-by-Letter Animation Configuration
  // ==========================================================================

  const LETTER_DELAY_MS = 50;  // Default delay between letters

  const LETTER_DELAYS = {
    'letter-faster': 20,
    'letter-fast': 35,
    'letter-slow': 80,
    'letter-slower': 120
  };

  // Get delay for a letter fragment
  function getLetterDelay(element) {
    for (const [cls, delay] of Object.entries(LETTER_DELAYS)) {
      if (element.classList.contains(cls)) {
        return delay;
      }
    }
    return LETTER_DELAY_MS;
  }

  // Check if this is a letter container fragment
  function isLetterContainer(element) {
    return element.classList.contains('letter-container');
  }

  // Get all letter characters in a container, sorted by index
  function getLettersInContainer(container) {
    const letters = Array.from(container.querySelectorAll('.letter-char'));

    // Sort by letter-index
    letters.sort((a, b) => {
      const aIdx = parseInt(a.getAttribute('data-letter-index') || '0');
      const bIdx = parseInt(b.getAttribute('data-letter-index') || '0');
      return aIdx - bIdx;
    });

    return letters;
  }

  // ==========================================================================
  // Animation Pairs Configuration
  // ==========================================================================

  // Mapping of entrance animations to their exit counterparts
  const animationPairs = {
    // Back animations (reverse direction: exit the way it came in)
    backInDown: 'backOutUp',
    backInLeft: 'backOutRight',
    backInRight: 'backOutLeft',
    backInUp: 'backOutDown',
    backOutDown: 'backInUp',
    backOutLeft: 'backInRight',
    backOutRight: 'backInLeft',
    backOutUp: 'backInDown',

    // Bouncing animations (reverse direction: exit the way it came in)
    bounceIn: 'bounceOut',
    bounceInDown: 'bounceOutUp',
    bounceInLeft: 'bounceOutRight',
    bounceInRight: 'bounceOutLeft',
    bounceInUp: 'bounceOutDown',
    bounceOut: 'bounceIn',
    bounceOutDown: 'bounceInUp',
    bounceOutLeft: 'bounceInRight',
    bounceOutRight: 'bounceInLeft',
    bounceOutUp: 'bounceInDown',

    // Fading animations (reverse direction: exit the way it came in)
    fadeIn: 'fadeOut',
    fadeInDown: 'fadeOutUp',
    fadeInDownBig: 'fadeOutUpBig',
    fadeInLeft: 'fadeOutLeft',
    fadeInLeftBig: 'fadeOutLeftBig',
    fadeInRight: 'fadeOutRight',
    fadeInRightBig: 'fadeOutRightBig',
    fadeInUp: 'fadeOutDown',
    fadeInUpBig: 'fadeOutDownBig',
    fadeInTopLeft: 'fadeOutTopLeft',
    fadeInTopRight: 'fadeOutTopRight',
    fadeInBottomLeft: 'fadeOutBottomLeft',
    fadeInBottomRight: 'fadeOutBottomRight',
    fadeOut: 'fadeIn',
    fadeOutDown: 'fadeInUp',
    fadeOutDownBig: 'fadeInUpBig',
    fadeOutLeft: 'fadeInLeft',
    fadeOutLeftBig: 'fadeInLeftBig',
    fadeOutRight: 'fadeInRight',
    fadeOutRightBig: 'fadeInRightBig',
    fadeOutUp: 'fadeInDown',
    fadeOutUpBig: 'fadeInDownBig',
    fadeOutTopLeft: 'fadeInTopLeft',
    fadeOutTopRight: 'fadeInTopRight',
    fadeOutBottomLeft: 'fadeInBottomLeft',
    fadeOutBottomRight: 'fadeInBottomRight',

    // Flippers
    flipInX: 'flipOutX',
    flipInY: 'flipOutY',
    flipOutX: 'flipInX',
    flipOutY: 'flipInY',

    // Lightspeed
    lightSpeedInRight: 'lightSpeedOutRight',
    lightSpeedInLeft: 'lightSpeedOutLeft',
    lightSpeedOutRight: 'lightSpeedInRight',
    lightSpeedOutLeft: 'lightSpeedInLeft',

    // Rotating animations
    rotateIn: 'rotateOut',
    rotateInDownLeft: 'rotateOutDownLeft',
    rotateInDownRight: 'rotateOutDownRight',
    rotateInUpLeft: 'rotateOutUpLeft',
    rotateInUpRight: 'rotateOutUpRight',
    rotateOut: 'rotateIn',
    rotateOutDownLeft: 'rotateInDownLeft',
    rotateOutDownRight: 'rotateInDownRight',
    rotateOutUpLeft: 'rotateInUpLeft',
    rotateOutUpRight: 'rotateInUpRight',

    // Sliding animations
    // Sliding animations (reverse direction: exit the way it came in)
    slideInDown: 'slideOutUp',
    slideInLeft: 'slideOutLeft',
    slideInRight: 'slideOutRight',
    slideInUp: 'slideOutDown',
    slideOutDown: 'slideInUp',
    slideOutLeft: 'slideInLeft',
    slideOutRight: 'slideInRight',
    slideOutUp: 'slideInDown',

    // Zooming animations
    // Zooming animations (reverse direction: exit the way it came in)
    zoomIn: 'zoomOut',
    zoomInDown: 'zoomOutUp',
    zoomInLeft: 'zoomOutLeft',
    zoomInRight: 'zoomOutRight',
    zoomInUp: 'zoomOutDown',
    zoomOut: 'zoomIn',
    zoomOutDown: 'zoomInUp',
    zoomOutLeft: 'zoomInLeft',
    zoomOutRight: 'zoomInRight',
    zoomOutUp: 'zoomInDown',

    // Specials
    jackInTheBox: 'zoomOut',
    rollIn: 'rollOut',
    rollOut: 'rollIn',
    hinge: 'fadeIn',

    // ==========================================================================
    // Magic.css Animations
    // ==========================================================================

    // Magic.css - Bling
    puffIn: 'puffOut',
    puffOut: 'puffIn',
    vanishIn: 'vanishOut',
    vanishOut: 'vanishIn',

    // Magic.css - Perspective
    perspectiveDown: 'perspectiveDownReturn',
    perspectiveUp: 'perspectiveUpReturn',
    perspectiveLeft: 'perspectiveLeftReturn',
    perspectiveRight: 'perspectiveRightReturn',
    perspectiveDownReturn: 'perspectiveDown',
    perspectiveUpReturn: 'perspectiveUp',
    perspectiveLeftReturn: 'perspectiveLeft',
    perspectiveRightReturn: 'perspectiveRight',

    // Magic.css - Space
    spaceInDown: 'spaceOutDown',
    spaceInUp: 'spaceOutUp',
    spaceInLeft: 'spaceOutLeft',
    spaceInRight: 'spaceOutRight',
    spaceOutDown: 'spaceInDown',
    spaceOutUp: 'spaceInUp',
    spaceOutLeft: 'spaceInLeft',
    spaceOutRight: 'spaceInRight',

    // Magic.css - Boing
    boingInUp: 'boingOutDown',
    boingOutDown: 'boingInUp',

    // Magic.css - Swash
    swashIn: 'swashOut',
    swashOut: 'swashIn',

    // Magic.css - Tin
    tinDownIn: 'tinDownOut',
    tinUpIn: 'tinUpOut',
    tinLeftIn: 'tinLeftOut',
    tinRightIn: 'tinRightOut',
    tinDownOut: 'tinDownIn',
    tinUpOut: 'tinUpIn',
    tinLeftOut: 'tinLeftIn',
    tinRightOut: 'tinRightIn',

    // Magic.css - Attention seekers (replay same animation)
    magic: 'magic',
    twisterInDown: 'twisterInDown',
    twisterInUp: 'twisterInUp'
  };

  // Get all animation class names
  const allAnimations = Object.keys(animationPairs);

  // Find which animation class an element has
  function getAnimationClass(element) {
    for (const anim of allAnimations) {
      if (element.classList.contains(anim)) {
        return anim;
      }
    }
    return null;
  }

  // Get animation duration based on speed utility class
  function getAnimationDuration(element) {
    if (element.classList.contains('slower')) return '3s';
    if (element.classList.contains('slow')) return '2s';
    if (element.classList.contains('fast')) return '800ms';
    if (element.classList.contains('faster')) return '500ms';
    return '1s';
  }

  // Apply animation to element
  function applyAnimation(element, animationName, keepVisible) {
    // Remove any existing animation
    element.style.setProperty('animation-name', 'none');

    // If keepVisible, force the element to stay visible during animation
    if (keepVisible) {
      element.style.setProperty('opacity', '1', 'important');
      element.style.setProperty('visibility', 'visible', 'important');
    }

    // Force reflow
    element.offsetHeight;

    // Apply new animation
    element.style.setProperty('animation-name', animationName, 'important');
    element.style.setProperty('animation-duration', getAnimationDuration(element), 'important');
    element.style.setProperty('animation-fill-mode', 'both', 'important');

    // If keepVisible, clean up after animation ends
    if (keepVisible) {
      element.addEventListener('animationend', function handler() {
        element.style.removeProperty('opacity');
        element.style.removeProperty('visibility');
        element.style.removeProperty('animation-name');
        element.style.removeProperty('animation-duration');
        element.style.removeProperty('animation-fill-mode');
        element.removeEventListener('animationend', handler);
      });
    }
  }

  // Wait for Reveal to be ready
  function setupReveal() {
    if (typeof Reveal !== 'undefined') {
      // Check if Reveal is already initialized
      if (Reveal.isReady()) {
        initMoreFragments();
      } else {
        Reveal.on('ready', function() {
          initMoreFragments();
        });
      }
    }
  }

  if (document.readyState === 'complete') {
    setupReveal();
  } else {
    window.addEventListener('load', setupReveal);
  }

  // Get all fragments with the same index in the current slide
  function getFragmentsWithSameIndex(fragment) {
    const index = fragment.getAttribute('data-fragment-index');
    if (index === null) return [fragment];

    const slide = fragment.closest('section');
    if (!slide) return [fragment];

    return Array.from(slide.querySelectorAll(`.fragment[data-fragment-index="${index}"]`));
  }

  function initMoreFragments() {
    // Fragment shown - forward navigation
    Reveal.on('fragmentshown', function(event) {
      const fragment = event.fragment;

      // Handle letter-by-letter animations (container-based)
      if (isLetterContainer(fragment)) {
        const letters = getLettersInContainer(fragment);
        if (letters.length === 0) return;

        const delay = getLetterDelay(fragment);

        letters.forEach(function(letter, index) {
          setTimeout(function() {
            const animClass = getAnimationClass(letter);
            if (animClass && animationPairs[animClass]) {
              applyAnimation(letter, animClass, false);
            }
            letter.classList.add('letter-visible');
          }, index * delay);
        });
        return;
      }

      // Handle regular fragments
      const fragments = getFragmentsWithSameIndex(fragment);

      fragments.forEach(function(frag) {
        const animClass = getAnimationClass(frag);
        if (animClass && animationPairs[animClass]) {
          applyAnimation(frag, animClass, false);
        }
      });
    });

    // Fragment hidden - backward navigation
    Reveal.on('fragmenthidden', function(event) {
      const fragment = event.fragment;

      // Handle letter-by-letter animations (reverse order, container-based)
      if (isLetterContainer(fragment)) {
        const letters = getLettersInContainer(fragment);
        if (letters.length === 0) return;

        const delay = getLetterDelay(fragment);

        // Reverse the array for backwards animation
        const reversedLetters = [...letters].reverse();

        reversedLetters.forEach(function(letter, index) {
          setTimeout(function() {
            const animClass = getAnimationClass(letter);
            if (animClass && animationPairs[animClass]) {
              applyAnimation(letter, animationPairs[animClass], true);
            }
            letter.classList.remove('letter-visible');
          }, index * delay);
        });
        return;
      }

      // Handle regular fragments
      const fragments = getFragmentsWithSameIndex(fragment);

      fragments.forEach(function(frag) {
        const animClass = getAnimationClass(frag);
        if (animClass && animationPairs[animClass]) {
          applyAnimation(frag, animationPairs[animClass], true);
        }
      });
    });
  }
})();
