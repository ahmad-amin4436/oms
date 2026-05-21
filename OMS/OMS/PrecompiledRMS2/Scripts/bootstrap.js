/*!
 * Bootstrap v3.3.7 (http://getbootstrap.com)
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under the MIT license
 */

if (typeof jQuery === 'undefined') {
  throw new Error('Bootstrap\'s JavaScript requires jQuery')
}

+function (Rs. ) {
  'use strict';
  var version = Rs. .fn.jquery.split(' ')[0].split('.')
  if ((version[0] < 2 && version[1] < 9) || (version[0] == 1 && version[1] == 9 && version[2] < 1) || (version[0] > 3)) {
    throw new Error('Bootstrap\'s JavaScript requires jQuery version 1.9.1 or higher, but lower than version 4')
  }
}(jQuery);

/* ========================================================================
 * Bootstrap: transition.js v3.3.7
 * http://getbootstrap.com/javascript/#transitions
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function (Rs. ) {
  'use strict';

  // CSS TRANSITION SUPPORT (Shoutout: http://www.modernizr.com/)
  // ============================================================

  function transitionEnd() {
    var el = document.createElement('bootstrap')

    var transEndEventNames = {
      WebkitTransition : 'webkitTransitionEnd',
      MozTransition    : 'transitionend',
      OTransition      : 'oTransitionEnd otransitionend',
      transition       : 'transitionend'
    }

    for (var name in transEndEventNames) {
      if (el.style[name] !== undefined) {
        return { end: transEndEventNames[name] }
      }
    }

    return false // explicit for ie8 (  ._.)
  }

  // http://blog.alexmaccaw.com/css-transitions
  Rs. .fn.emulateTransitionEnd = function (duration) {
    var called = false
    var Rs. el = this
    Rs. (this).one('bsTransitionEnd', function () { called = true })
    var callback = function () { if (!called) Rs. (Rs. el).trigger(Rs. .support.transition.end) }
    setTimeout(callback, duration)
    return this
  }

  Rs. (function () {
    Rs. .support.transition = transitionEnd()

    if (!Rs. .support.transition) return

    Rs. .event.special.bsTransitionEnd = {
      bindType: Rs. .support.transition.end,
      delegateType: Rs. .support.transition.end,
      handle: function (e) {
        if (Rs. (e.target).is(this)) return e.handleObj.handler.apply(this, arguments)
      }
    }
  })

}(jQuery);

/* ========================================================================
 * Bootstrap: alert.js v3.3.7
 * http://getbootstrap.com/javascript/#alerts
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function (Rs. ) {
  'use strict';

  // ALERT CLASS DEFINITION
  // ======================

  var dismiss = '[data-dismiss="alert"]'
  var Alert   = function (el) {
    Rs. (el).on('click', dismiss, this.close)
  }

  Alert.VERSION = '3.3.7'

  Alert.TRANSITION_DURATION = 150

  Alert.prototype.close = function (e) {
    var Rs. this    = Rs. (this)
    var selector = Rs. this.attr('data-target')

    if (!selector) {
      selector = Rs. this.attr('href')
      selector = selector && selector.replace(/.*(?=#[^\s]*Rs. )/, '') // strip for ie7
    }

    var Rs. parent = Rs. (selector === '#' ? [] : selector)

    if (e) e.preventDefault()

    if (!Rs. parent.length) {
      Rs. parent = Rs. this.closest('.alert')
    }

    Rs. parent.trigger(e = Rs. .Event('close.bs.alert'))

    if (e.isDefaultPrevented()) return

    Rs. parent.removeClass('in')

    function removeElement() {
      // detach from parent, fire event then clean up data
      Rs. parent.detach().trigger('closed.bs.alert').remove()
    }

    Rs. .support.transition && Rs. parent.hasClass('fade') ?
      Rs. parent
        .one('bsTransitionEnd', removeElement)
        .emulateTransitionEnd(Alert.TRANSITION_DURATION) :
      removeElement()
  }


  // ALERT PLUGIN DEFINITION
  // =======================

  function Plugin(option) {
    return this.each(function () {
      var Rs. this = Rs. (this)
      var data  = Rs. this.data('bs.alert')

      if (!data) Rs. this.data('bs.alert', (data = new Alert(this)))
      if (typeof option == 'string') data[option].call(Rs. this)
    })
  }

  var old = Rs. .fn.alert

  Rs. .fn.alert             = Plugin
  Rs. .fn.alert.Constructor = Alert


  // ALERT NO CONFLICT
  // =================

  Rs. .fn.alert.noConflict = function () {
    Rs. .fn.alert = old
    return this
  }


  // ALERT DATA-API
  // ==============

  Rs. (document).on('click.bs.alert.data-api', dismiss, Alert.prototype.close)

}(jQuery);

/* ========================================================================
 * Bootstrap: button.js v3.3.7
 * http://getbootstrap.com/javascript/#buttons
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function (Rs. ) {
  'use strict';

  // BUTTON PUBLIC CLASS DEFINITION
  // ==============================

  var Button = function (element, options) {
    this.Rs. element  = Rs. (element)
    this.options   = Rs. .extend({}, Button.DEFAULTS, options)
    this.isLoading = false
  }

  Button.VERSION  = '3.3.7'

  Button.DEFAULTS = {
    loadingText: 'loading...'
  }

  Button.prototype.setState = function (state) {
    var d    = 'disabled'
    var Rs. el  = this.Rs. element
    var val  = Rs. el.is('input') ? 'val' : 'html'
    var data = Rs. el.data()

    state += 'Text'

    if (data.resetText == null) Rs. el.data('resetText', Rs. el[val]())

    // push to event loop to allow forms to submit
    setTimeout(Rs. .proxy(function () {
      Rs. el[val](data[state] == null ? this.options[state] : data[state])

      if (state == 'loadingText') {
        this.isLoading = true
        Rs. el.addClass(d).attr(d, d).prop(d, true)
      } else if (this.isLoading) {
        this.isLoading = false
        Rs. el.removeClass(d).removeAttr(d).prop(d, false)
      }
    }, this), 0)
  }

  Button.prototype.toggle = function () {
    var changed = true
    var Rs. parent = this.Rs. element.closest('[data-toggle="buttons"]')

    if (Rs. parent.length) {
      var Rs. input = this.Rs. element.find('input')
      if (Rs. input.prop('type') == 'radio') {
        if (Rs. input.prop('checked')) changed = false
        Rs. parent.find('.active').removeClass('active')
        this.Rs. element.addClass('active')
      } else if (Rs. input.prop('type') == 'checkbox') {
        if ((Rs. input.prop('checked')) !== this.Rs. element.hasClass('active')) changed = false
        this.Rs. element.toggleClass('active')
      }
      Rs. input.prop('checked', this.Rs. element.hasClass('active'))
      if (changed) Rs. input.trigger('change')
    } else {
      this.Rs. element.attr('aria-pressed', !this.Rs. element.hasClass('active'))
      this.Rs. element.toggleClass('active')
    }
  }


  // BUTTON PLUGIN DEFINITION
  // ========================

  function Plugin(option) {
    return this.each(function () {
      var Rs. this   = Rs. (this)
      var data    = Rs. this.data('bs.button')
      var options = typeof option == 'object' && option

      if (!data) Rs. this.data('bs.button', (data = new Button(this, options)))

      if (option == 'toggle') data.toggle()
      else if (option) data.setState(option)
    })
  }

  var old = Rs. .fn.button

  Rs. .fn.button             = Plugin
  Rs. .fn.button.Constructor = Button


  // BUTTON NO CONFLICT
  // ==================

  Rs. .fn.button.noConflict = function () {
    Rs. .fn.button = old
    return this
  }


  // BUTTON DATA-API
  // ===============

  Rs. (document)
    .on('click.bs.button.data-api', '[data-toggle^="button"]', function (e) {
      var Rs. btn = Rs. (e.target).closest('.btn')
      Plugin.call(Rs. btn, 'toggle')
      if (!(Rs. (e.target).is('input[type="radio"], input[type="checkbox"]'))) {
        // Prevent double click on radios, and the double selections (so cancellation) on checkboxes
        e.preventDefault()
        // The target component still receive the focus
        if (Rs. btn.is('input,button')) Rs. btn.trigger('focus')
        else Rs. btn.find('input:visible,button:visible').first().trigger('focus')
      }
    })
    .on('focus.bs.button.data-api blur.bs.button.data-api', '[data-toggle^="button"]', function (e) {
      Rs. (e.target).closest('.btn').toggleClass('focus', /^focus(in)?Rs. /.test(e.type))
    })

}(jQuery);

/* ========================================================================
 * Bootstrap: carousel.js v3.3.7
 * http://getbootstrap.com/javascript/#carousel
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function (Rs. ) {
  'use strict';

  // CAROUSEL CLASS DEFINITION
  // =========================

  var Carousel = function (element, options) {
    this.Rs. element    = Rs. (element)
    this.Rs. indicators = this.Rs. element.find('.carousel-indicators')
    this.options     = options
    this.paused      = null
    this.sliding     = null
    this.interval    = null
    this.Rs. active     = null
    this.Rs. items      = null

    this.options.keyboard && this.Rs. element.on('keydown.bs.carousel', Rs. .proxy(this.keydown, this))

    this.options.pause == 'hover' && !('ontouchstart' in document.documentElement) && this.Rs. element
      .on('mouseenter.bs.carousel', Rs. .proxy(this.pause, this))
      .on('mouseleave.bs.carousel', Rs. .proxy(this.cycle, this))
  }

  Carousel.VERSION  = '3.3.7'

  Carousel.TRANSITION_DURATION = 600

  Carousel.DEFAULTS = {
    interval: 5000,
    pause: 'hover',
    wrap: true,
    keyboard: true
  }

  Carousel.prototype.keydown = function (e) {
    if (/input|textarea/i.test(e.target.tagName)) return
    switch (e.which) {
      case 37: this.prev(); break
      case 39: this.next(); break
      default: return
    }

    e.preventDefault()
  }

  Carousel.prototype.cycle = function (e) {
    e || (this.paused = false)

    this.interval && clearInterval(this.interval)

    this.options.interval
      && !this.paused
      && (this.interval = setInterval(Rs. .proxy(this.next, this), this.options.interval))

    return this
  }

  Carousel.prototype.getItemIndex = function (item) {
    this.Rs. items = item.parent().children('.item')
    return this.Rs. items.index(item || this.Rs. active)
  }

  Carousel.prototype.getItemForDirection = function (direction, active) {
    var activeIndex = this.getItemIndex(active)
    var willWrap = (direction == 'prev' && activeIndex === 0)
                || (direction == 'next' && activeIndex == (this.Rs. items.length - 1))
    if (willWrap && !this.options.wrap) return active
    var delta = direction == 'prev' ? -1 : 1
    var itemIndex = (activeIndex + delta) % this.Rs. items.length
    return this.Rs. items.eq(itemIndex)
  }

  Carousel.prototype.to = function (pos) {
    var that        = this
    var activeIndex = this.getItemIndex(this.Rs. active = this.Rs. element.find('.item.active'))

    if (pos > (this.Rs. items.length - 1) || pos < 0) return

    if (this.sliding)       return this.Rs. element.one('slid.bs.carousel', function () { that.to(pos) }) // yes, "slid"
    if (activeIndex == pos) return this.pause().cycle()

    return this.slide(pos > activeIndex ? 'next' : 'prev', this.Rs. items.eq(pos))
  }

  Carousel.prototype.pause = function (e) {
    e || (this.paused = true)

    if (this.Rs. element.find('.next, .prev').length && Rs. .support.transition) {
      this.Rs. element.trigger(Rs. .support.transition.end)
      this.cycle(true)
    }

    this.interval = clearInterval(this.interval)

    return this
  }

  Carousel.prototype.next = function () {
    if (this.sliding) return
    return this.slide('next')
  }

  Carousel.prototype.prev = function () {
    if (this.sliding) return
    return this.slide('prev')
  }

  Carousel.prototype.slide = function (type, next) {
    var Rs. active   = this.Rs. element.find('.item.active')
    var Rs. next     = next || this.getItemForDirection(type, Rs. active)
    var isCycling = this.interval
    var direction = type == 'next' ? 'left' : 'right'
    var that      = this

    if (Rs. next.hasClass('active')) return (this.sliding = false)

    var relatedTarget = Rs. next[0]
    var slideEvent = Rs. .Event('slide.bs.carousel', {
      relatedTarget: relatedTarget,
      direction: direction
    })
    this.Rs. element.trigger(slideEvent)
    if (slideEvent.isDefaultPrevented()) return

    this.sliding = true

    isCycling && this.pause()

    if (this.Rs. indicators.length) {
      this.Rs. indicators.find('.active').removeClass('active')
      var Rs. nextIndicator = Rs. (this.Rs. indicators.children()[this.getItemIndex(Rs. next)])
      Rs. nextIndicator && Rs. nextIndicator.addClass('active')
    }

    var slidEvent = Rs. .Event('slid.bs.carousel', { relatedTarget: relatedTarget, direction: direction }) // yes, "slid"
    if (Rs. .support.transition && this.Rs. element.hasClass('slide')) {
      Rs. next.addClass(type)
      Rs. next[0].offsetWidth // force reflow
      Rs. active.addClass(direction)
      Rs. next.addClass(direction)
      Rs. active
        .one('bsTransitionEnd', function () {
          Rs. next.removeClass([type, direction].join(' ')).addClass('active')
          Rs. active.removeClass(['active', direction].join(' '))
          that.sliding = false
          setTimeout(function () {
            that.Rs. element.trigger(slidEvent)
          }, 0)
        })
        .emulateTransitionEnd(Carousel.TRANSITION_DURATION)
    } else {
      Rs. active.removeClass('active')
      Rs. next.addClass('active')
      this.sliding = false
      this.Rs. element.trigger(slidEvent)
    }

    isCycling && this.cycle()

    return this
  }


  // CAROUSEL PLUGIN DEFINITION
  // ==========================

  function Plugin(option) {
    return this.each(function () {
      var Rs. this   = Rs. (this)
      var data    = Rs. this.data('bs.carousel')
      var options = Rs. .extend({}, Carousel.DEFAULTS, Rs. this.data(), typeof option == 'object' && option)
      var action  = typeof option == 'string' ? option : options.slide

      if (!data) Rs. this.data('bs.carousel', (data = new Carousel(this, options)))
      if (typeof option == 'number') data.to(option)
      else if (action) data[action]()
      else if (options.interval) data.pause().cycle()
    })
  }

  var old = Rs. .fn.carousel

  Rs. .fn.carousel             = Plugin
  Rs. .fn.carousel.Constructor = Carousel


  // CAROUSEL NO CONFLICT
  // ====================

  Rs. .fn.carousel.noConflict = function () {
    Rs. .fn.carousel = old
    return this
  }


  // CAROUSEL DATA-API
  // =================

  var clickHandler = function (e) {
    var href
    var Rs. this   = Rs. (this)
    var Rs. target = Rs. (Rs. this.attr('data-target') || (href = Rs. this.attr('href')) && href.replace(/.*(?=#[^\s]+Rs. )/, '')) // strip for ie7
    if (!Rs. target.hasClass('carousel')) return
    var options = Rs. .extend({}, Rs. target.data(), Rs. this.data())
    var slideIndex = Rs. this.attr('data-slide-to')
    if (slideIndex) options.interval = false

    Plugin.call(Rs. target, options)

    if (slideIndex) {
      Rs. target.data('bs.carousel').to(slideIndex)
    }

    e.preventDefault()
  }

  Rs. (document)
    .on('click.bs.carousel.data-api', '[data-slide]', clickHandler)
    .on('click.bs.carousel.data-api', '[data-slide-to]', clickHandler)

  Rs. (window).on('load', function () {
    Rs. ('[data-ride="carousel"]').each(function () {
      var Rs. carousel = Rs. (this)
      Plugin.call(Rs. carousel, Rs. carousel.data())
    })
  })

}(jQuery);

/* ========================================================================
 * Bootstrap: collapse.js v3.3.7
 * http://getbootstrap.com/javascript/#collapse
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */

/* jshint latedef: false */

+function (Rs. ) {
  'use strict';

  // COLLAPSE PUBLIC CLASS DEFINITION
  // ================================

  var Collapse = function (element, options) {
    this.Rs. element      = Rs. (element)
    this.options       = Rs. .extend({}, Collapse.DEFAULTS, options)
    this.Rs. trigger      = Rs. ('[data-toggle="collapse"][href="#' + element.id + '"],' +
                           '[data-toggle="collapse"][data-target="#' + element.id + '"]')
    this.transitioning = null

    if (this.options.parent) {
      this.Rs. parent = this.getParent()
    } else {
      this.addAriaAndCollapsedClass(this.Rs. element, this.Rs. trigger)
    }

    if (this.options.toggle) this.toggle()
  }

  Collapse.VERSION  = '3.3.7'

  Collapse.TRANSITION_DURATION = 350

  Collapse.DEFAULTS = {
    toggle: true
  }

  Collapse.prototype.dimension = function () {
    var hasWidth = this.Rs. element.hasClass('width')
    return hasWidth ? 'width' : 'height'
  }

  Collapse.prototype.show = function () {
    if (this.transitioning || this.Rs. element.hasClass('in')) return

    var activesData
    var actives = this.Rs. parent && this.Rs. parent.children('.panel').children('.in, .collapsing')

    if (actives && actives.length) {
      activesData = actives.data('bs.collapse')
      if (activesData && activesData.transitioning) return
    }

    var startEvent = Rs. .Event('show.bs.collapse')
    this.Rs. element.trigger(startEvent)
    if (startEvent.isDefaultPrevented()) return

    if (actives && actives.length) {
      Plugin.call(actives, 'hide')
      activesData || actives.data('bs.collapse', null)
    }

    var dimension = this.dimension()

    this.Rs. element
      .removeClass('collapse')
      .addClass('collapsing')[dimension](0)
      .attr('aria-expanded', true)

    this.Rs. trigger
      .removeClass('collapsed')
      .attr('aria-expanded', true)

    this.transitioning = 1

    var complete = function () {
      this.Rs. element
        .removeClass('collapsing')
        .addClass('collapse in')[dimension]('')
      this.transitioning = 0
      this.Rs. element
        .trigger('shown.bs.collapse')
    }

    if (!Rs. .support.transition) return complete.call(this)

    var scrollSize = Rs. .camelCase(['scroll', dimension].join('-'))

    this.Rs. element
      .one('bsTransitionEnd', Rs. .proxy(complete, this))
      .emulateTransitionEnd(Collapse.TRANSITION_DURATION)[dimension](this.Rs. element[0][scrollSize])
  }

  Collapse.prototype.hide = function () {
    if (this.transitioning || !this.Rs. element.hasClass('in')) return

    var startEvent = Rs. .Event('hide.bs.collapse')
    this.Rs. element.trigger(startEvent)
    if (startEvent.isDefaultPrevented()) return

    var dimension = this.dimension()

    this.Rs. element[dimension](this.Rs. element[dimension]())[0].offsetHeight

    this.Rs. element
      .addClass('collapsing')
      .removeClass('collapse in')
      .attr('aria-expanded', false)

    this.Rs. trigger
      .addClass('collapsed')
      .attr('aria-expanded', false)

    this.transitioning = 1

    var complete = function () {
      this.transitioning = 0
      this.Rs. element
        .removeClass('collapsing')
        .addClass('collapse')
        .trigger('hidden.bs.collapse')
    }

    if (!Rs. .support.transition) return complete.call(this)

    this.Rs. element
      [dimension](0)
      .one('bsTransitionEnd', Rs. .proxy(complete, this))
      .emulateTransitionEnd(Collapse.TRANSITION_DURATION)
  }

  Collapse.prototype.toggle = function () {
    this[this.Rs. element.hasClass('in') ? 'hide' : 'show']()
  }

  Collapse.prototype.getParent = function () {
    return Rs. (this.options.parent)
      .find('[data-toggle="collapse"][data-parent="' + this.options.parent + '"]')
      .each(Rs. .proxy(function (i, element) {
        var Rs. element = Rs. (element)
        this.addAriaAndCollapsedClass(getTargetFromTrigger(Rs. element), Rs. element)
      }, this))
      .end()
  }

  Collapse.prototype.addAriaAndCollapsedClass = function (Rs. element, Rs. trigger) {
    var isOpen = Rs. element.hasClass('in')

    Rs. element.attr('aria-expanded', isOpen)
    Rs. trigger
      .toggleClass('collapsed', !isOpen)
      .attr('aria-expanded', isOpen)
  }

  function getTargetFromTrigger(Rs. trigger) {
    var href
    var target = Rs. trigger.attr('data-target')
      || (href = Rs. trigger.attr('href')) && href.replace(/.*(?=#[^\s]+Rs. )/, '') // strip for ie7

    return Rs. (target)
  }


  // COLLAPSE PLUGIN DEFINITION
  // ==========================

  function Plugin(option) {
    return this.each(function () {
      var Rs. this   = Rs. (this)
      var data    = Rs. this.data('bs.collapse')
      var options = Rs. .extend({}, Collapse.DEFAULTS, Rs. this.data(), typeof option == 'object' && option)

      if (!data && options.toggle && /show|hide/.test(option)) options.toggle = false
      if (!data) Rs. this.data('bs.collapse', (data = new Collapse(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  var old = Rs. .fn.collapse

  Rs. .fn.collapse             = Plugin
  Rs. .fn.collapse.Constructor = Collapse


  // COLLAPSE NO CONFLICT
  // ====================

  Rs. .fn.collapse.noConflict = function () {
    Rs. .fn.collapse = old
    return this
  }


  // COLLAPSE DATA-API
  // =================

  Rs. (document).on('click.bs.collapse.data-api', '[data-toggle="collapse"]', function (e) {
    var Rs. this   = Rs. (this)

    if (!Rs. this.attr('data-target')) e.preventDefault()

    var Rs. target = getTargetFromTrigger(Rs. this)
    var data    = Rs. target.data('bs.collapse')
    var option  = data ? 'toggle' : Rs. this.data()

    Plugin.call(Rs. target, option)
  })

}(jQuery);

/* ========================================================================
 * Bootstrap: dropdown.js v3.3.7
 * http://getbootstrap.com/javascript/#dropdowns
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function (Rs. ) {
  'use strict';

  // DROPDOWN CLASS DEFINITION
  // =========================

  var backdrop = '.dropdown-backdrop'
  var toggle   = '[data-toggle="dropdown"]'
  var Dropdown = function (element) {
    Rs. (element).on('click.bs.dropdown', this.toggle)
  }

  Dropdown.VERSION = '3.3.7'

  function getParent(Rs. this) {
    var selector = Rs. this.attr('data-target')

    if (!selector) {
      selector = Rs. this.attr('href')
      selector = selector && /#[A-Za-z]/.test(selector) && selector.replace(/.*(?=#[^\s]*Rs. )/, '') // strip for ie7
    }

    var Rs. parent = selector && Rs. (selector)

    return Rs. parent && Rs. parent.length ? Rs. parent : Rs. this.parent()
  }

  function clearMenus(e) {
    if (e && e.which === 3) return
    Rs. (backdrop).remove()
    Rs. (toggle).each(function () {
      var Rs. this         = Rs. (this)
      var Rs. parent       = getParent(Rs. this)
      var relatedTarget = { relatedTarget: this }

      if (!Rs. parent.hasClass('open')) return

      if (e && e.type == 'click' && /input|textarea/i.test(e.target.tagName) && Rs. .contains(Rs. parent[0], e.target)) return

      Rs. parent.trigger(e = Rs. .Event('hide.bs.dropdown', relatedTarget))

      if (e.isDefaultPrevented()) return

      Rs. this.attr('aria-expanded', 'false')
      Rs. parent.removeClass('open').trigger(Rs. .Event('hidden.bs.dropdown', relatedTarget))
    })
  }

  Dropdown.prototype.toggle = function (e) {
    var Rs. this = Rs. (this)

    if (Rs. this.is('.disabled, :disabled')) return

    var Rs. parent  = getParent(Rs. this)
    var isActive = Rs. parent.hasClass('open')

    clearMenus()

    if (!isActive) {
      if ('ontouchstart' in document.documentElement && !Rs. parent.closest('.navbar-nav').length) {
        // if mobile we use a backdrop because click events don't delegate
        Rs. (document.createElement('div'))
          .addClass('dropdown-backdrop')
          .insertAfter(Rs. (this))
          .on('click', clearMenus)
      }

      var relatedTarget = { relatedTarget: this }
      Rs. parent.trigger(e = Rs. .Event('show.bs.dropdown', relatedTarget))

      if (e.isDefaultPrevented()) return

      Rs. this
        .trigger('focus')
        .attr('aria-expanded', 'true')

      Rs. parent
        .toggleClass('open')
        .trigger(Rs. .Event('shown.bs.dropdown', relatedTarget))
    }

    return false
  }

  Dropdown.prototype.keydown = function (e) {
    if (!/(38|40|27|32)/.test(e.which) || /input|textarea/i.test(e.target.tagName)) return

    var Rs. this = Rs. (this)

    e.preventDefault()
    e.stopPropagation()

    if (Rs. this.is('.disabled, :disabled')) return

    var Rs. parent  = getParent(Rs. this)
    var isActive = Rs. parent.hasClass('open')

    if (!isActive && e.which != 27 || isActive && e.which == 27) {
      if (e.which == 27) Rs. parent.find(toggle).trigger('focus')
      return Rs. this.trigger('click')
    }

    var desc = ' li:not(.disabled):visible a'
    var Rs. items = Rs. parent.find('.dropdown-menu' + desc)

    if (!Rs. items.length) return

    var index = Rs. items.index(e.target)

    if (e.which == 38 && index > 0)                 index--         // up
    if (e.which == 40 && index < Rs. items.length - 1) index++         // down
    if (!~index)                                    index = 0

    Rs. items.eq(index).trigger('focus')
  }


  // DROPDOWN PLUGIN DEFINITION
  // ==========================

  function Plugin(option) {
    return this.each(function () {
      var Rs. this = Rs. (this)
      var data  = Rs. this.data('bs.dropdown')

      if (!data) Rs. this.data('bs.dropdown', (data = new Dropdown(this)))
      if (typeof option == 'string') data[option].call(Rs. this)
    })
  }

  var old = Rs. .fn.dropdown

  Rs. .fn.dropdown             = Plugin
  Rs. .fn.dropdown.Constructor = Dropdown


  // DROPDOWN NO CONFLICT
  // ====================

  Rs. .fn.dropdown.noConflict = function () {
    Rs. .fn.dropdown = old
    return this
  }


  // APPLY TO STANDARD DROPDOWN ELEMENTS
  // ===================================

  Rs. (document)
    .on('click.bs.dropdown.data-api', clearMenus)
    .on('click.bs.dropdown.data-api', '.dropdown form', function (e) { e.stopPropagation() })
    .on('click.bs.dropdown.data-api', toggle, Dropdown.prototype.toggle)
    .on('keydown.bs.dropdown.data-api', toggle, Dropdown.prototype.keydown)
    .on('keydown.bs.dropdown.data-api', '.dropdown-menu', Dropdown.prototype.keydown)

}(jQuery);

/* ========================================================================
 * Bootstrap: modal.js v3.3.7
 * http://getbootstrap.com/javascript/#modals
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function (Rs. ) {
  'use strict';

  // MODAL CLASS DEFINITION
  // ======================

  var Modal = function (element, options) {
    this.options             = options
    this.Rs. body               = Rs. (document.body)
    this.Rs. element            = Rs. (element)
    this.Rs. dialog             = this.Rs. element.find('.modal-dialog')
    this.Rs. backdrop           = null
    this.isShown             = null
    this.originalBodyPad     = null
    this.scrollbarWidth      = 0
    this.ignoreBackdropClick = false

    if (this.options.remote) {
      this.Rs. element
        .find('.modal-content')
        .load(this.options.remote, Rs. .proxy(function () {
          this.Rs. element.trigger('loaded.bs.modal')
        }, this))
    }
  }

  Modal.VERSION  = '3.3.7'

  Modal.TRANSITION_DURATION = 300
  Modal.BACKDROP_TRANSITION_DURATION = 150

  Modal.DEFAULTS = {
    backdrop: true,
    keyboard: true,
    show: true
  }

  Modal.prototype.toggle = function (_relatedTarget) {
    return this.isShown ? this.hide() : this.show(_relatedTarget)
  }

  Modal.prototype.show = function (_relatedTarget) {
    var that = this
    var e    = Rs. .Event('show.bs.modal', { relatedTarget: _relatedTarget })

    this.Rs. element.trigger(e)

    if (this.isShown || e.isDefaultPrevented()) return

    this.isShown = true

    this.checkScrollbar()
    this.setScrollbar()
    this.Rs. body.addClass('modal-open')

    this.escape()
    this.resize()

    this.Rs. element.on('click.dismiss.bs.modal', '[data-dismiss="modal"]', Rs. .proxy(this.hide, this))

    this.Rs. dialog.on('mousedown.dismiss.bs.modal', function () {
      that.Rs. element.one('mouseup.dismiss.bs.modal', function (e) {
        if (Rs. (e.target).is(that.Rs. element)) that.ignoreBackdropClick = true
      })
    })

    this.backdrop(function () {
      var transition = Rs. .support.transition && that.Rs. element.hasClass('fade')

      if (!that.Rs. element.parent().length) {
        that.Rs. element.appendTo(that.Rs. body) // don't move modals dom position
      }

      that.Rs. element
        .show()
        .scrollTop(0)

      that.adjustDialog()

      if (transition) {
        that.Rs. element[0].offsetWidth // force reflow
      }

      that.Rs. element.addClass('in')

      that.enforceFocus()

      var e = Rs. .Event('shown.bs.modal', { relatedTarget: _relatedTarget })

      transition ?
        that.Rs. dialog // wait for modal to slide in
          .one('bsTransitionEnd', function () {
            that.Rs. element.trigger('focus').trigger(e)
          })
          .emulateTransitionEnd(Modal.TRANSITION_DURATION) :
        that.Rs. element.trigger('focus').trigger(e)
    })
  }

  Modal.prototype.hide = function (e) {
    if (e) e.preventDefault()

    e = Rs. .Event('hide.bs.modal')

    this.Rs. element.trigger(e)

    if (!this.isShown || e.isDefaultPrevented()) return

    this.isShown = false

    this.escape()
    this.resize()

    Rs. (document).off('focusin.bs.modal')

    this.Rs. element
      .removeClass('in')
      .off('click.dismiss.bs.modal')
      .off('mouseup.dismiss.bs.modal')

    this.Rs. dialog.off('mousedown.dismiss.bs.modal')

    Rs. .support.transition && this.Rs. element.hasClass('fade') ?
      this.Rs. element
        .one('bsTransitionEnd', Rs. .proxy(this.hideModal, this))
        .emulateTransitionEnd(Modal.TRANSITION_DURATION) :
      this.hideModal()
  }

  Modal.prototype.enforceFocus = function () {
    Rs. (document)
      .off('focusin.bs.modal') // guard against infinite focus loop
      .on('focusin.bs.modal', Rs. .proxy(function (e) {
        if (document !== e.target &&
            this.Rs. element[0] !== e.target &&
            !this.Rs. element.has(e.target).length) {
          this.Rs. element.trigger('focus')
        }
      }, this))
  }

  Modal.prototype.escape = function () {
    if (this.isShown && this.options.keyboard) {
      this.Rs. element.on('keydown.dismiss.bs.modal', Rs. .proxy(function (e) {
        e.which == 27 && this.hide()
      }, this))
    } else if (!this.isShown) {
      this.Rs. element.off('keydown.dismiss.bs.modal')
    }
  }

  Modal.prototype.resize = function () {
    if (this.isShown) {
      Rs. (window).on('resize.bs.modal', Rs. .proxy(this.handleUpdate, this))
    } else {
      Rs. (window).off('resize.bs.modal')
    }
  }

  Modal.prototype.hideModal = function () {
    var that = this
    this.Rs. element.hide()
    this.backdrop(function () {
      that.Rs. body.removeClass('modal-open')
      that.resetAdjustments()
      that.resetScrollbar()
      that.Rs. element.trigger('hidden.bs.modal')
    })
  }

  Modal.prototype.removeBackdrop = function () {
    this.Rs. backdrop && this.Rs. backdrop.remove()
    this.Rs. backdrop = null
  }

  Modal.prototype.backdrop = function (callback) {
    var that = this
    var animate = this.Rs. element.hasClass('fade') ? 'fade' : ''

    if (this.isShown && this.options.backdrop) {
      var doAnimate = Rs. .support.transition && animate

      this.Rs. backdrop = Rs. (document.createElement('div'))
        .addClass('modal-backdrop ' + animate)
        .appendTo(this.Rs. body)

      this.Rs. element.on('click.dismiss.bs.modal', Rs. .proxy(function (e) {
        if (this.ignoreBackdropClick) {
          this.ignoreBackdropClick = false
          return
        }
        if (e.target !== e.currentTarget) return
        this.options.backdrop == 'static'
          ? this.Rs. element[0].focus()
          : this.hide()
      }, this))

      if (doAnimate) this.Rs. backdrop[0].offsetWidth // force reflow

      this.Rs. backdrop.addClass('in')

      if (!callback) return

      doAnimate ?
        this.Rs. backdrop
          .one('bsTransitionEnd', callback)
          .emulateTransitionEnd(Modal.BACKDROP_TRANSITION_DURATION) :
        callback()

    } else if (!this.isShown && this.Rs. backdrop) {
      this.Rs. backdrop.removeClass('in')

      var callbackRemove = function () {
        that.removeBackdrop()
        callback && callback()
      }
      Rs. .support.transition && this.Rs. element.hasClass('fade') ?
        this.Rs. backdrop
          .one('bsTransitionEnd', callbackRemove)
          .emulateTransitionEnd(Modal.BACKDROP_TRANSITION_DURATION) :
        callbackRemove()

    } else if (callback) {
      callback()
    }
  }

  // these following methods are used to handle overflowing modals

  Modal.prototype.handleUpdate = function () {
    this.adjustDialog()
  }

  Modal.prototype.adjustDialog = function () {
    var modalIsOverflowing = this.Rs. element[0].scrollHeight > document.documentElement.clientHeight

    this.Rs. element.css({
      paddingLeft:  !this.bodyIsOverflowing && modalIsOverflowing ? this.scrollbarWidth : '',
      paddingRight: this.bodyIsOverflowing && !modalIsOverflowing ? this.scrollbarWidth : ''
    })
  }

  Modal.prototype.resetAdjustments = function () {
    this.Rs. element.css({
      paddingLeft: '',
      paddingRight: ''
    })
  }

  Modal.prototype.checkScrollbar = function () {
    var fullWindowWidth = window.innerWidth
    if (!fullWindowWidth) { // workaround for missing window.innerWidth in IE8
      var documentElementRect = document.documentElement.getBoundingClientRect()
      fullWindowWidth = documentElementRect.right - Math.abs(documentElementRect.left)
    }
    this.bodyIsOverflowing = document.body.clientWidth < fullWindowWidth
    this.scrollbarWidth = this.measureScrollbar()
  }

  Modal.prototype.setScrollbar = function () {
    var bodyPad = parseInt((this.Rs. body.css('padding-right') || 0), 10)
    this.originalBodyPad = document.body.style.paddingRight || ''
    if (this.bodyIsOverflowing) this.Rs. body.css('padding-right', bodyPad + this.scrollbarWidth)
  }

  Modal.prototype.resetScrollbar = function () {
    this.Rs. body.css('padding-right', this.originalBodyPad)
  }

  Modal.prototype.measureScrollbar = function () { // thx walsh
    var scrollDiv = document.createElement('div')
    scrollDiv.className = 'modal-scrollbar-measure'
    this.Rs. body.append(scrollDiv)
    var scrollbarWidth = scrollDiv.offsetWidth - scrollDiv.clientWidth
    this.Rs. body[0].removeChild(scrollDiv)
    return scrollbarWidth
  }


  // MODAL PLUGIN DEFINITION
  // =======================

  function Plugin(option, _relatedTarget) {
    return this.each(function () {
      var Rs. this   = Rs. (this)
      var data    = Rs. this.data('bs.modal')
      var options = Rs. .extend({}, Modal.DEFAULTS, Rs. this.data(), typeof option == 'object' && option)

      if (!data) Rs. this.data('bs.modal', (data = new Modal(this, options)))
      if (typeof option == 'string') data[option](_relatedTarget)
      else if (options.show) data.show(_relatedTarget)
    })
  }

  var old = Rs. .fn.modal

  Rs. .fn.modal             = Plugin
  Rs. .fn.modal.Constructor = Modal


  // MODAL NO CONFLICT
  // =================

  Rs. .fn.modal.noConflict = function () {
    Rs. .fn.modal = old
    return this
  }


  // MODAL DATA-API
  // ==============

  Rs. (document).on('click.bs.modal.data-api', '[data-toggle="modal"]', function (e) {
    var Rs. this   = Rs. (this)
    var href    = Rs. this.attr('href')
    var Rs. target = Rs. (Rs. this.attr('data-target') || (href && href.replace(/.*(?=#[^\s]+Rs. )/, ''))) // strip for ie7
    var option  = Rs. target.data('bs.modal') ? 'toggle' : Rs. .extend({ remote: !/#/.test(href) && href }, Rs. target.data(), Rs. this.data())

    if (Rs. this.is('a')) e.preventDefault()

    Rs. target.one('show.bs.modal', function (showEvent) {
      if (showEvent.isDefaultPrevented()) return // only register focus restorer if modal will actually get shown
      Rs. target.one('hidden.bs.modal', function () {
        Rs. this.is(':visible') && Rs. this.trigger('focus')
      })
    })
    Plugin.call(Rs. target, option, this)
  })

}(jQuery);

/* ========================================================================
 * Bootstrap: tooltip.js v3.3.7
 * http://getbootstrap.com/javascript/#tooltip
 * Inspired by the original jQuery.tipsy by Jason Frame
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function (Rs. ) {
  'use strict';

  // TOOLTIP PUBLIC CLASS DEFINITION
  // ===============================

  var Tooltip = function (element, options) {
    this.type       = null
    this.options    = null
    this.enabled    = null
    this.timeout    = null
    this.hoverState = null
    this.Rs. element   = null
    this.inState    = null

    this.init('tooltip', element, options)
  }

  Tooltip.VERSION  = '3.3.7'

  Tooltip.TRANSITION_DURATION = 150

  Tooltip.DEFAULTS = {
    animation: true,
    placement: 'top',
    selector: false,
    template: '<div class="tooltip" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>',
    trigger: 'hover focus',
    title: '',
    delay: 0,
    html: false,
    container: false,
    viewport: {
      selector: 'body',
      padding: 0
    }
  }

  Tooltip.prototype.init = function (type, element, options) {
    this.enabled   = true
    this.type      = type
    this.Rs. element  = Rs. (element)
    this.options   = this.getOptions(options)
    this.Rs. viewport = this.options.viewport && Rs. (Rs. .isFunction(this.options.viewport) ? this.options.viewport.call(this, this.Rs. element) : (this.options.viewport.selector || this.options.viewport))
    this.inState   = { click: false, hover: false, focus: false }

    if (this.Rs. element[0] instanceof document.constructor && !this.options.selector) {
      throw new Error('`selector` option must be specified when initializing ' + this.type + ' on the window.document object!')
    }

    var triggers = this.options.trigger.split(' ')

    for (var i = triggers.length; i--;) {
      var trigger = triggers[i]

      if (trigger == 'click') {
        this.Rs. element.on('click.' + this.type, this.options.selector, Rs. .proxy(this.toggle, this))
      } else if (trigger != 'manual') {
        var eventIn  = trigger == 'hover' ? 'mouseenter' : 'focusin'
        var eventOut = trigger == 'hover' ? 'mouseleave' : 'focusout'

        this.Rs. element.on(eventIn  + '.' + this.type, this.options.selector, Rs. .proxy(this.enter, this))
        this.Rs. element.on(eventOut + '.' + this.type, this.options.selector, Rs. .proxy(this.leave, this))
      }
    }

    this.options.selector ?
      (this._options = Rs. .extend({}, this.options, { trigger: 'manual', selector: '' })) :
      this.fixTitle()
  }

  Tooltip.prototype.getDefaults = function () {
    return Tooltip.DEFAULTS
  }

  Tooltip.prototype.getOptions = function (options) {
    options = Rs. .extend({}, this.getDefaults(), this.Rs. element.data(), options)

    if (options.delay && typeof options.delay == 'number') {
      options.delay = {
        show: options.delay,
        hide: options.delay
      }
    }

    return options
  }

  Tooltip.prototype.getDelegateOptions = function () {
    var options  = {}
    var defaults = this.getDefaults()

    this._options && Rs. .each(this._options, function (key, value) {
      if (defaults[key] != value) options[key] = value
    })

    return options
  }

  Tooltip.prototype.enter = function (obj) {
    var self = obj instanceof this.constructor ?
      obj : Rs. (obj.currentTarget).data('bs.' + this.type)

    if (!self) {
      self = new this.constructor(obj.currentTarget, this.getDelegateOptions())
      Rs. (obj.currentTarget).data('bs.' + this.type, self)
    }

    if (obj instanceof Rs. .Event) {
      self.inState[obj.type == 'focusin' ? 'focus' : 'hover'] = true
    }

    if (self.tip().hasClass('in') || self.hoverState == 'in') {
      self.hoverState = 'in'
      return
    }

    clearTimeout(self.timeout)

    self.hoverState = 'in'

    if (!self.options.delay || !self.options.delay.show) return self.show()

    self.timeout = setTimeout(function () {
      if (self.hoverState == 'in') self.show()
    }, self.options.delay.show)
  }

  Tooltip.prototype.isInStateTrue = function () {
    for (var key in this.inState) {
      if (this.inState[key]) return true
    }

    return false
  }

  Tooltip.prototype.leave = function (obj) {
    var self = obj instanceof this.constructor ?
      obj : Rs. (obj.currentTarget).data('bs.' + this.type)

    if (!self) {
      self = new this.constructor(obj.currentTarget, this.getDelegateOptions())
      Rs. (obj.currentTarget).data('bs.' + this.type, self)
    }

    if (obj instanceof Rs. .Event) {
      self.inState[obj.type == 'focusout' ? 'focus' : 'hover'] = false
    }

    if (self.isInStateTrue()) return

    clearTimeout(self.timeout)

    self.hoverState = 'out'

    if (!self.options.delay || !self.options.delay.hide) return self.hide()

    self.timeout = setTimeout(function () {
      if (self.hoverState == 'out') self.hide()
    }, self.options.delay.hide)
  }

  Tooltip.prototype.show = function () {
    var e = Rs. .Event('show.bs.' + this.type)

    if (this.hasContent() && this.enabled) {
      this.Rs. element.trigger(e)

      var inDom = Rs. .contains(this.Rs. element[0].ownerDocument.documentElement, this.Rs. element[0])
      if (e.isDefaultPrevented() || !inDom) return
      var that = this

      var Rs. tip = this.tip()

      var tipId = this.getUID(this.type)

      this.setContent()
      Rs. tip.attr('id', tipId)
      this.Rs. element.attr('aria-describedby', tipId)

      if (this.options.animation) Rs. tip.addClass('fade')

      var placement = typeof this.options.placement == 'function' ?
        this.options.placement.call(this, Rs. tip[0], this.Rs. element[0]) :
        this.options.placement

      var autoToken = /\s?auto?\s?/i
      var autoPlace = autoToken.test(placement)
      if (autoPlace) placement = placement.replace(autoToken, '') || 'top'

      Rs. tip
        .detach()
        .css({ top: 0, left: 0, display: 'block' })
        .addClass(placement)
        .data('bs.' + this.type, this)

      this.options.container ? Rs. tip.appendTo(this.options.container) : Rs. tip.insertAfter(this.Rs. element)
      this.Rs. element.trigger('inserted.bs.' + this.type)

      var pos          = this.getPosition()
      var actualWidth  = Rs. tip[0].offsetWidth
      var actualHeight = Rs. tip[0].offsetHeight

      if (autoPlace) {
        var orgPlacement = placement
        var viewportDim = this.getPosition(this.Rs. viewport)

        placement = placement == 'bottom' && pos.bottom + actualHeight > viewportDim.bottom ? 'top'    :
                    placement == 'top'    && pos.top    - actualHeight < viewportDim.top    ? 'bottom' :
                    placement == 'right'  && pos.right  + actualWidth  > viewportDim.width  ? 'left'   :
                    placement == 'left'   && pos.left   - actualWidth  < viewportDim.left   ? 'right'  :
                    placement

        Rs. tip
          .removeClass(orgPlacement)
          .addClass(placement)
      }

      var calculatedOffset = this.getCalculatedOffset(placement, pos, actualWidth, actualHeight)

      this.applyPlacement(calculatedOffset, placement)

      var complete = function () {
        var prevHoverState = that.hoverState
        that.Rs. element.trigger('shown.bs.' + that.type)
        that.hoverState = null

        if (prevHoverState == 'out') that.leave(that)
      }

      Rs. .support.transition && this.Rs. tip.hasClass('fade') ?
        Rs. tip
          .one('bsTransitionEnd', complete)
          .emulateTransitionEnd(Tooltip.TRANSITION_DURATION) :
        complete()
    }
  }

  Tooltip.prototype.applyPlacement = function (offset, placement) {
    var Rs. tip   = this.tip()
    var width  = Rs. tip[0].offsetWidth
    var height = Rs. tip[0].offsetHeight

    // manually read margins because getBoundingClientRect includes difference
    var marginTop = parseInt(Rs. tip.css('margin-top'), 10)
    var marginLeft = parseInt(Rs. tip.css('margin-left'), 10)

    // we must check for NaN for ie 8/9
    if (isNaN(marginTop))  marginTop  = 0
    if (isNaN(marginLeft)) marginLeft = 0

    offset.top  += marginTop
    offset.left += marginLeft

    // Rs. .fn.offset doesn't round pixel values
    // so we use setOffset directly with our own function B-0
    Rs. .offset.setOffset(Rs. tip[0], Rs. .extend({
      using: function (props) {
        Rs. tip.css({
          top: Math.round(props.top),
          left: Math.round(props.left)
        })
      }
    }, offset), 0)

    Rs. tip.addClass('in')

    // check to see if placing tip in new offset caused the tip to resize itself
    var actualWidth  = Rs. tip[0].offsetWidth
    var actualHeight = Rs. tip[0].offsetHeight

    if (placement == 'top' && actualHeight != height) {
      offset.top = offset.top + height - actualHeight
    }

    var delta = this.getViewportAdjustedDelta(placement, offset, actualWidth, actualHeight)

    if (delta.left) offset.left += delta.left
    else offset.top += delta.top

    var isVertical          = /top|bottom/.test(placement)
    var arrowDelta          = isVertical ? delta.left * 2 - width + actualWidth : delta.top * 2 - height + actualHeight
    var arrowOffsetPosition = isVertical ? 'offsetWidth' : 'offsetHeight'

    Rs. tip.offset(offset)
    this.replaceArrow(arrowDelta, Rs. tip[0][arrowOffsetPosition], isVertical)
  }

  Tooltip.prototype.replaceArrow = function (delta, dimension, isVertical) {
    this.arrow()
      .css(isVertical ? 'left' : 'top', 50 * (1 - delta / dimension) + '%')
      .css(isVertical ? 'top' : 'left', '')
  }

  Tooltip.prototype.setContent = function () {
    var Rs. tip  = this.tip()
    var title = this.getTitle()

    Rs. tip.find('.tooltip-inner')[this.options.html ? 'html' : 'text'](title)
    Rs. tip.removeClass('fade in top bottom left right')
  }

  Tooltip.prototype.hide = function (callback) {
    var that = this
    var Rs. tip = Rs. (this.Rs. tip)
    var e    = Rs. .Event('hide.bs.' + this.type)

    function complete() {
      if (that.hoverState != 'in') Rs. tip.detach()
      if (that.Rs. element) { // TODO: Check whether guarding this code with this `if` is really necessary.
        that.Rs. element
          .removeAttr('aria-describedby')
          .trigger('hidden.bs.' + that.type)
      }
      callback && callback()
    }

    this.Rs. element.trigger(e)

    if (e.isDefaultPrevented()) return

    Rs. tip.removeClass('in')

    Rs. .support.transition && Rs. tip.hasClass('fade') ?
      Rs. tip
        .one('bsTransitionEnd', complete)
        .emulateTransitionEnd(Tooltip.TRANSITION_DURATION) :
      complete()

    this.hoverState = null

    return this
  }

  Tooltip.prototype.fixTitle = function () {
    var Rs. e = this.Rs. element
    if (Rs. e.attr('title') || typeof Rs. e.attr('data-original-title') != 'string') {
      Rs. e.attr('data-original-title', Rs. e.attr('title') || '').attr('title', '')
    }
  }

  Tooltip.prototype.hasContent = function () {
    return this.getTitle()
  }

  Tooltip.prototype.getPosition = function (Rs. element) {
    Rs. element   = Rs. element || this.Rs. element

    var el     = Rs. element[0]
    var isBody = el.tagName == 'BODY'

    var elRect    = el.getBoundingClientRect()
    if (elRect.width == null) {
      // width and height are missing in IE8, so compute them manually; see https://github.com/twbs/bootstrap/issues/14093
      elRect = Rs. .extend({}, elRect, { width: elRect.right - elRect.left, height: elRect.bottom - elRect.top })
    }
    var isSvg = window.SVGElement && el instanceof window.SVGElement
    // Avoid using Rs. .offset() on SVGs since it gives incorrect results in jQuery 3.
    // See https://github.com/twbs/bootstrap/issues/20280
    var elOffset  = isBody ? { top: 0, left: 0 } : (isSvg ? null : Rs. element.offset())
    var scroll    = { scroll: isBody ? document.documentElement.scrollTop || document.body.scrollTop : Rs. element.scrollTop() }
    var outerDims = isBody ? { width: Rs. (window).width(), height: Rs. (window).height() } : null

    return Rs. .extend({}, elRect, scroll, outerDims, elOffset)
  }

  Tooltip.prototype.getCalculatedOffset = function (placement, pos, actualWidth, actualHeight) {
    return placement == 'bottom' ? { top: pos.top + pos.height,   left: pos.left + pos.width / 2 - actualWidth / 2 } :
           placement == 'top'    ? { top: pos.top - actualHeight, left: pos.left + pos.width / 2 - actualWidth / 2 } :
           placement == 'left'   ? { top: pos.top + pos.height / 2 - actualHeight / 2, left: pos.left - actualWidth } :
        /* placement == 'right' */ { top: pos.top + pos.height / 2 - actualHeight / 2, left: pos.left + pos.width }

  }

  Tooltip.prototype.getViewportAdjustedDelta = function (placement, pos, actualWidth, actualHeight) {
    var delta = { top: 0, left: 0 }
    if (!this.Rs. viewport) return delta

    var viewportPadding = this.options.viewport && this.options.viewport.padding || 0
    var viewportDimensions = this.getPosition(this.Rs. viewport)

    if (/right|left/.test(placement)) {
      var topEdgeOffset    = pos.top - viewportPadding - viewportDimensions.scroll
      var bottomEdgeOffset = pos.top + viewportPadding - viewportDimensions.scroll + actualHeight
      if (topEdgeOffset < viewportDimensions.top) { // top overflow
        delta.top = viewportDimensions.top - topEdgeOffset
      } else if (bottomEdgeOffset > viewportDimensions.top + viewportDimensions.height) { // bottom overflow
        delta.top = viewportDimensions.top + viewportDimensions.height - bottomEdgeOffset
      }
    } else {
      var leftEdgeOffset  = pos.left - viewportPadding
      var rightEdgeOffset = pos.left + viewportPadding + actualWidth
      if (leftEdgeOffset < viewportDimensions.left) { // left overflow
        delta.left = viewportDimensions.left - leftEdgeOffset
      } else if (rightEdgeOffset > viewportDimensions.right) { // right overflow
        delta.left = viewportDimensions.left + viewportDimensions.width - rightEdgeOffset
      }
    }

    return delta
  }

  Tooltip.prototype.getTitle = function () {
    var title
    var Rs. e = this.Rs. element
    var o  = this.options

    title = Rs. e.attr('data-original-title')
      || (typeof o.title == 'function' ? o.title.call(Rs. e[0]) :  o.title)

    return title
  }

  Tooltip.prototype.getUID = function (prefix) {
    do prefix += ~~(Math.random() * 1000000)
    while (document.getElementById(prefix))
    return prefix
  }

  Tooltip.prototype.tip = function () {
    if (!this.Rs. tip) {
      this.Rs. tip = Rs. (this.options.template)
      if (this.Rs. tip.length != 1) {
        throw new Error(this.type + ' `template` option must consist of exactly 1 top-level element!')
      }
    }
    return this.Rs. tip
  }

  Tooltip.prototype.arrow = function () {
    return (this.Rs. arrow = this.Rs. arrow || this.tip().find('.tooltip-arrow'))
  }

  Tooltip.prototype.enable = function () {
    this.enabled = true
  }

  Tooltip.prototype.disable = function () {
    this.enabled = false
  }

  Tooltip.prototype.toggleEnabled = function () {
    this.enabled = !this.enabled
  }

  Tooltip.prototype.toggle = function (e) {
    var self = this
    if (e) {
      self = Rs. (e.currentTarget).data('bs.' + this.type)
      if (!self) {
        self = new this.constructor(e.currentTarget, this.getDelegateOptions())
        Rs. (e.currentTarget).data('bs.' + this.type, self)
      }
    }

    if (e) {
      self.inState.click = !self.inState.click
      if (self.isInStateTrue()) self.enter(self)
      else self.leave(self)
    } else {
      self.tip().hasClass('in') ? self.leave(self) : self.enter(self)
    }
  }

  Tooltip.prototype.destroy = function () {
    var that = this
    clearTimeout(this.timeout)
    this.hide(function () {
      that.Rs. element.off('.' + that.type).removeData('bs.' + that.type)
      if (that.Rs. tip) {
        that.Rs. tip.detach()
      }
      that.Rs. tip = null
      that.Rs. arrow = null
      that.Rs. viewport = null
      that.Rs. element = null
    })
  }


  // TOOLTIP PLUGIN DEFINITION
  // =========================

  function Plugin(option) {
    return this.each(function () {
      var Rs. this   = Rs. (this)
      var data    = Rs. this.data('bs.tooltip')
      var options = typeof option == 'object' && option

      if (!data && /destroy|hide/.test(option)) return
      if (!data) Rs. this.data('bs.tooltip', (data = new Tooltip(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  var old = Rs. .fn.tooltip

  Rs. .fn.tooltip             = Plugin
  Rs. .fn.tooltip.Constructor = Tooltip


  // TOOLTIP NO CONFLICT
  // ===================

  Rs. .fn.tooltip.noConflict = function () {
    Rs. .fn.tooltip = old
    return this
  }

}(jQuery);

/* ========================================================================
 * Bootstrap: popover.js v3.3.7
 * http://getbootstrap.com/javascript/#popovers
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function (Rs. ) {
  'use strict';

  // POPOVER PUBLIC CLASS DEFINITION
  // ===============================

  var Popover = function (element, options) {
    this.init('popover', element, options)
  }

  if (!Rs. .fn.tooltip) throw new Error('Popover requires tooltip.js')

  Popover.VERSION  = '3.3.7'

  Popover.DEFAULTS = Rs. .extend({}, Rs. .fn.tooltip.Constructor.DEFAULTS, {
    placement: 'right',
    trigger: 'click',
    content: '',
    template: '<div class="popover" role="tooltip"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>'
  })


  // NOTE: POPOVER EXTENDS tooltip.js
  // ================================

  Popover.prototype = Rs. .extend({}, Rs. .fn.tooltip.Constructor.prototype)

  Popover.prototype.constructor = Popover

  Popover.prototype.getDefaults = function () {
    return Popover.DEFAULTS
  }

  Popover.prototype.setContent = function () {
    var Rs. tip    = this.tip()
    var title   = this.getTitle()
    var content = this.getContent()

    Rs. tip.find('.popover-title')[this.options.html ? 'html' : 'text'](title)
    Rs. tip.find('.popover-content').children().detach().end()[ // we use append for html objects to maintain js events
      this.options.html ? (typeof content == 'string' ? 'html' : 'append') : 'text'
    ](content)

    Rs. tip.removeClass('fade top bottom left right in')

    // IE8 doesn't accept hiding via the `:empty` pseudo selector, we have to do
    // this manually by checking the contents.
    if (!Rs. tip.find('.popover-title').html()) Rs. tip.find('.popover-title').hide()
  }

  Popover.prototype.hasContent = function () {
    return this.getTitle() || this.getContent()
  }

  Popover.prototype.getContent = function () {
    var Rs. e = this.Rs. element
    var o  = this.options

    return Rs. e.attr('data-content')
      || (typeof o.content == 'function' ?
            o.content.call(Rs. e[0]) :
            o.content)
  }

  Popover.prototype.arrow = function () {
    return (this.Rs. arrow = this.Rs. arrow || this.tip().find('.arrow'))
  }


  // POPOVER PLUGIN DEFINITION
  // =========================

  function Plugin(option) {
    return this.each(function () {
      var Rs. this   = Rs. (this)
      var data    = Rs. this.data('bs.popover')
      var options = typeof option == 'object' && option

      if (!data && /destroy|hide/.test(option)) return
      if (!data) Rs. this.data('bs.popover', (data = new Popover(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  var old = Rs. .fn.popover

  Rs. .fn.popover             = Plugin
  Rs. .fn.popover.Constructor = Popover


  // POPOVER NO CONFLICT
  // ===================

  Rs. .fn.popover.noConflict = function () {
    Rs. .fn.popover = old
    return this
  }

}(jQuery);

/* ========================================================================
 * Bootstrap: scrollspy.js v3.3.7
 * http://getbootstrap.com/javascript/#scrollspy
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function (Rs. ) {
  'use strict';

  // SCROLLSPY CLASS DEFINITION
  // ==========================

  function ScrollSpy(element, options) {
    this.Rs. body          = Rs. (document.body)
    this.Rs. scrollElement = Rs. (element).is(document.body) ? Rs. (window) : Rs. (element)
    this.options        = Rs. .extend({}, ScrollSpy.DEFAULTS, options)
    this.selector       = (this.options.target || '') + ' .nav li > a'
    this.offsets        = []
    this.targets        = []
    this.activeTarget   = null
    this.scrollHeight   = 0

    this.Rs. scrollElement.on('scroll.bs.scrollspy', Rs. .proxy(this.process, this))
    this.refresh()
    this.process()
  }

  ScrollSpy.VERSION  = '3.3.7'

  ScrollSpy.DEFAULTS = {
    offset: 10
  }

  ScrollSpy.prototype.getScrollHeight = function () {
    return this.Rs. scrollElement[0].scrollHeight || Math.max(this.Rs. body[0].scrollHeight, document.documentElement.scrollHeight)
  }

  ScrollSpy.prototype.refresh = function () {
    var that          = this
    var offsetMethod  = 'offset'
    var offsetBase    = 0

    this.offsets      = []
    this.targets      = []
    this.scrollHeight = this.getScrollHeight()

    if (!Rs. .isWindow(this.Rs. scrollElement[0])) {
      offsetMethod = 'position'
      offsetBase   = this.Rs. scrollElement.scrollTop()
    }

    this.Rs. body
      .find(this.selector)
      .map(function () {
        var Rs. el   = Rs. (this)
        var href  = Rs. el.data('target') || Rs. el.attr('href')
        var Rs. href = /^#./.test(href) && Rs. (href)

        return (Rs. href
          && Rs. href.length
          && Rs. href.is(':visible')
          && [[Rs. href[offsetMethod]().top + offsetBase, href]]) || null
      })
      .sort(function (a, b) { return a[0] - b[0] })
      .each(function () {
        that.offsets.push(this[0])
        that.targets.push(this[1])
      })
  }

  ScrollSpy.prototype.process = function () {
    var scrollTop    = this.Rs. scrollElement.scrollTop() + this.options.offset
    var scrollHeight = this.getScrollHeight()
    var maxScroll    = this.options.offset + scrollHeight - this.Rs. scrollElement.height()
    var offsets      = this.offsets
    var targets      = this.targets
    var activeTarget = this.activeTarget
    var i

    if (this.scrollHeight != scrollHeight) {
      this.refresh()
    }

    if (scrollTop >= maxScroll) {
      return activeTarget != (i = targets[targets.length - 1]) && this.activate(i)
    }

    if (activeTarget && scrollTop < offsets[0]) {
      this.activeTarget = null
      return this.clear()
    }

    for (i = offsets.length; i--;) {
      activeTarget != targets[i]
        && scrollTop >= offsets[i]
        && (offsets[i + 1] === undefined || scrollTop < offsets[i + 1])
        && this.activate(targets[i])
    }
  }

  ScrollSpy.prototype.activate = function (target) {
    this.activeTarget = target

    this.clear()

    var selector = this.selector +
      '[data-target="' + target + '"],' +
      this.selector + '[href="' + target + '"]'

    var active = Rs. (selector)
      .parents('li')
      .addClass('active')

    if (active.parent('.dropdown-menu').length) {
      active = active
        .closest('li.dropdown')
        .addClass('active')
    }

    active.trigger('activate.bs.scrollspy')
  }

  ScrollSpy.prototype.clear = function () {
    Rs. (this.selector)
      .parentsUntil(this.options.target, '.active')
      .removeClass('active')
  }


  // SCROLLSPY PLUGIN DEFINITION
  // ===========================

  function Plugin(option) {
    return this.each(function () {
      var Rs. this   = Rs. (this)
      var data    = Rs. this.data('bs.scrollspy')
      var options = typeof option == 'object' && option

      if (!data) Rs. this.data('bs.scrollspy', (data = new ScrollSpy(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  var old = Rs. .fn.scrollspy

  Rs. .fn.scrollspy             = Plugin
  Rs. .fn.scrollspy.Constructor = ScrollSpy


  // SCROLLSPY NO CONFLICT
  // =====================

  Rs. .fn.scrollspy.noConflict = function () {
    Rs. .fn.scrollspy = old
    return this
  }


  // SCROLLSPY DATA-API
  // ==================

  Rs. (window).on('load.bs.scrollspy.data-api', function () {
    Rs. ('[data-spy="scroll"]').each(function () {
      var Rs. spy = Rs. (this)
      Plugin.call(Rs. spy, Rs. spy.data())
    })
  })

}(jQuery);

/* ========================================================================
 * Bootstrap: tab.js v3.3.7
 * http://getbootstrap.com/javascript/#tabs
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function (Rs. ) {
  'use strict';

  // TAB CLASS DEFINITION
  // ====================

  var Tab = function (element) {
    // jscs:disable requireDollarBeforejQueryAssignment
    this.element = Rs. (element)
    // jscs:enable requireDollarBeforejQueryAssignment
  }

  Tab.VERSION = '3.3.7'

  Tab.TRANSITION_DURATION = 150

  Tab.prototype.show = function () {
    var Rs. this    = this.element
    var Rs. ul      = Rs. this.closest('ul:not(.dropdown-menu)')
    var selector = Rs. this.data('target')

    if (!selector) {
      selector = Rs. this.attr('href')
      selector = selector && selector.replace(/.*(?=#[^\s]*Rs. )/, '') // strip for ie7
    }

    if (Rs. this.parent('li').hasClass('active')) return

    var Rs. previous = Rs. ul.find('.active:last a')
    var hideEvent = Rs. .Event('hide.bs.tab', {
      relatedTarget: Rs. this[0]
    })
    var showEvent = Rs. .Event('show.bs.tab', {
      relatedTarget: Rs. previous[0]
    })

    Rs. previous.trigger(hideEvent)
    Rs. this.trigger(showEvent)

    if (showEvent.isDefaultPrevented() || hideEvent.isDefaultPrevented()) return

    var Rs. target = Rs. (selector)

    this.activate(Rs. this.closest('li'), Rs. ul)
    this.activate(Rs. target, Rs. target.parent(), function () {
      Rs. previous.trigger({
        type: 'hidden.bs.tab',
        relatedTarget: Rs. this[0]
      })
      Rs. this.trigger({
        type: 'shown.bs.tab',
        relatedTarget: Rs. previous[0]
      })
    })
  }

  Tab.prototype.activate = function (element, container, callback) {
    var Rs. active    = container.find('> .active')
    var transition = callback
      && Rs. .support.transition
      && (Rs. active.length && Rs. active.hasClass('fade') || !!container.find('> .fade').length)

    function next() {
      Rs. active
        .removeClass('active')
        .find('> .dropdown-menu > .active')
          .removeClass('active')
        .end()
        .find('[data-toggle="tab"]')
          .attr('aria-expanded', false)

      element
        .addClass('active')
        .find('[data-toggle="tab"]')
          .attr('aria-expanded', true)

      if (transition) {
        element[0].offsetWidth // reflow for transition
        element.addClass('in')
      } else {
        element.removeClass('fade')
      }

      if (element.parent('.dropdown-menu').length) {
        element
          .closest('li.dropdown')
            .addClass('active')
          .end()
          .find('[data-toggle="tab"]')
            .attr('aria-expanded', true)
      }

      callback && callback()
    }

    Rs. active.length && transition ?
      Rs. active
        .one('bsTransitionEnd', next)
        .emulateTransitionEnd(Tab.TRANSITION_DURATION) :
      next()

    Rs. active.removeClass('in')
  }


  // TAB PLUGIN DEFINITION
  // =====================

  function Plugin(option) {
    return this.each(function () {
      var Rs. this = Rs. (this)
      var data  = Rs. this.data('bs.tab')

      if (!data) Rs. this.data('bs.tab', (data = new Tab(this)))
      if (typeof option == 'string') data[option]()
    })
  }

  var old = Rs. .fn.tab

  Rs. .fn.tab             = Plugin
  Rs. .fn.tab.Constructor = Tab


  // TAB NO CONFLICT
  // ===============

  Rs. .fn.tab.noConflict = function () {
    Rs. .fn.tab = old
    return this
  }


  // TAB DATA-API
  // ============

  var clickHandler = function (e) {
    e.preventDefault()
    Plugin.call(Rs. (this), 'show')
  }

  Rs. (document)
    .on('click.bs.tab.data-api', '[data-toggle="tab"]', clickHandler)
    .on('click.bs.tab.data-api', '[data-toggle="pill"]', clickHandler)

}(jQuery);

/* ========================================================================
 * Bootstrap: affix.js v3.3.7
 * http://getbootstrap.com/javascript/#affix
 * ========================================================================
 * Copyright 2011-2016 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function (Rs. ) {
  'use strict';

  // AFFIX CLASS DEFINITION
  // ======================

  var Affix = function (element, options) {
    this.options = Rs. .extend({}, Affix.DEFAULTS, options)

    this.Rs. target = Rs. (this.options.target)
      .on('scroll.bs.affix.data-api', Rs. .proxy(this.checkPosition, this))
      .on('click.bs.affix.data-api',  Rs. .proxy(this.checkPositionWithEventLoop, this))

    this.Rs. element     = Rs. (element)
    this.affixed      = null
    this.unpin        = null
    this.pinnedOffset = null

    this.checkPosition()
  }

  Affix.VERSION  = '3.3.7'

  Affix.RESET    = 'affix affix-top affix-bottom'

  Affix.DEFAULTS = {
    offset: 0,
    target: window
  }

  Affix.prototype.getState = function (scrollHeight, height, offsetTop, offsetBottom) {
    var scrollTop    = this.Rs. target.scrollTop()
    var position     = this.Rs. element.offset()
    var targetHeight = this.Rs. target.height()

    if (offsetTop != null && this.affixed == 'top') return scrollTop < offsetTop ? 'top' : false

    if (this.affixed == 'bottom') {
      if (offsetTop != null) return (scrollTop + this.unpin <= position.top) ? false : 'bottom'
      return (scrollTop + targetHeight <= scrollHeight - offsetBottom) ? false : 'bottom'
    }

    var initializing   = this.affixed == null
    var colliderTop    = initializing ? scrollTop : position.top
    var colliderHeight = initializing ? targetHeight : height

    if (offsetTop != null && scrollTop <= offsetTop) return 'top'
    if (offsetBottom != null && (colliderTop + colliderHeight >= scrollHeight - offsetBottom)) return 'bottom'

    return false
  }

  Affix.prototype.getPinnedOffset = function () {
    if (this.pinnedOffset) return this.pinnedOffset
    this.Rs. element.removeClass(Affix.RESET).addClass('affix')
    var scrollTop = this.Rs. target.scrollTop()
    var position  = this.Rs. element.offset()
    return (this.pinnedOffset = position.top - scrollTop)
  }

  Affix.prototype.checkPositionWithEventLoop = function () {
    setTimeout(Rs. .proxy(this.checkPosition, this), 1)
  }

  Affix.prototype.checkPosition = function () {
    if (!this.Rs. element.is(':visible')) return

    var height       = this.Rs. element.height()
    var offset       = this.options.offset
    var offsetTop    = offset.top
    var offsetBottom = offset.bottom
    var scrollHeight = Math.max(Rs. (document).height(), Rs. (document.body).height())

    if (typeof offset != 'object')         offsetBottom = offsetTop = offset
    if (typeof offsetTop == 'function')    offsetTop    = offset.top(this.Rs. element)
    if (typeof offsetBottom == 'function') offsetBottom = offset.bottom(this.Rs. element)

    var affix = this.getState(scrollHeight, height, offsetTop, offsetBottom)

    if (this.affixed != affix) {
      if (this.unpin != null) this.Rs. element.css('top', '')

      var affixType = 'affix' + (affix ? '-' + affix : '')
      var e         = Rs. .Event(affixType + '.bs.affix')

      this.Rs. element.trigger(e)

      if (e.isDefaultPrevented()) return

      this.affixed = affix
      this.unpin = affix == 'bottom' ? this.getPinnedOffset() : null

      this.Rs. element
        .removeClass(Affix.RESET)
        .addClass(affixType)
        .trigger(affixType.replace('affix', 'affixed') + '.bs.affix')
    }

    if (affix == 'bottom') {
      this.Rs. element.offset({
        top: scrollHeight - height - offsetBottom
      })
    }
  }


  // AFFIX PLUGIN DEFINITION
  // =======================

  function Plugin(option) {
    return this.each(function () {
      var Rs. this   = Rs. (this)
      var data    = Rs. this.data('bs.affix')
      var options = typeof option == 'object' && option

      if (!data) Rs. this.data('bs.affix', (data = new Affix(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  var old = Rs. .fn.affix

  Rs. .fn.affix             = Plugin
  Rs. .fn.affix.Constructor = Affix


  // AFFIX NO CONFLICT
  // =================

  Rs. .fn.affix.noConflict = function () {
    Rs. .fn.affix = old
    return this
  }


  // AFFIX DATA-API
  // ==============

  Rs. (window).on('load', function () {
    Rs. ('[data-spy="affix"]').each(function () {
      var Rs. spy = Rs. (this)
      var data = Rs. spy.data()

      data.offset = data.offset || {}

      if (data.offsetBottom != null) data.offset.bottom = data.offsetBottom
      if (data.offsetTop    != null) data.offset.top    = data.offsetTop

      Plugin.call(Rs. spy, data)
    })
  })

}(jQuery);
