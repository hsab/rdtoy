$ = require 'jquery'

lib = {}

template = 
	col: '<div class="col" />'
	btnGroup: '<div class="col btnGroup" />'
	item: '<div class="item" />'
	itemHeader: '<h4 class="itemHeader" />'
	itemLabel: '<h5 class="itemLabel" />'
	aButton: '<a class="button" />'
	icon: '<i class="fa" />'
	spanText: '<span class="text" />'
	button: '<button />'
	slider: '<input type="range" />'
	toggle: '<input type="checkbox" class="toggle" />'
	label: '<label />'

containerFactory = (html) ->
	return (->
		# args = id , classes , child
		args = Array.prototype.slice.call arguments
		child = args.pop()
		classes = args.pop()
		id = args.pop()
		# dom
		dom = $ html
		if classes then dom.addClass classes
		if child? then dom.append child
		if id? then dom.prop 'id' , id
		# return
		return dom
	)

# container type
lib.itemHeader = containerFactory template.itemHeader
lib.item       = containerFactory template.item
lib.col        = containerFactory template.col
lib.btnGroup   = containerFactory template.btnGroup
lib.spanText   = containerFactory template.spanText
lib.itemLabel  = containerFactory template.itemLabel
lib._button    = containerFactory template.button
lib._aButton   = containerFactory template.aButton

# non-container type
lib.icon = (icon) ->
	$ template.icon
		.addClass icon
lib.label = (id) ->
	$ template.label
		.prop 'for' , id

lib.animate =
	sliderText: ({
		dom
		durationIn = 100
		durationOut = 150
		reverse = false
		callback
	}) ->
		dom.stop()
		dom.css 'position' , 'relative'
		delta = dom.height()
		animIn =
			top: if reverse then -delta else delta
		animOut =
			top: 0
		# options
		optOut = 
			duration : durationOut
			complete : ->
				dom.css 'position' , ''
				dom.css 'top' , ''
		optIn =
			duration : durationIn
			complete : ->
				dom.css 'top' , if reverse then delta else -delta
				if callback? then callback()
				dom.animate animOut , optOut
		# animate
		dom.animate animIn , optIn

lib.sectionHeader = ({
	icon
	name
}) ->
	dom = $ '<h3 class="sectionHeader" />'
	if icon then dom.append @icon icon
	if name then dom.append @spanText name
	return dom

lib.section = ({
	icon
	name
	child = []
}) ->
	dom = $ '<section class="section" />'
	dom.addClass name
	phaseButton = @button
		link: true
		classes: 'section-minimize-button'
		name: 'minimize'
		icon: 'fa-angle-up'
	dom_minimal = 'minimal'
	dom_minimized = 'minimized'
	phaseButton.click ->
		if dom.hasClass dom_minimized
			phaseButton.css 'transform' , 'rotateZ(0)'
			dom.removeClass dom_minimal
			dom.removeClass dom_minimized
		else if dom.hasClass dom_minimal
			phaseButton.css 'transform' , 'rotateZ(180deg)'
			dom.addClass dom_minimized
		else
			dom.addClass dom_minimal
	child.unshift phaseButton
	child.unshift @sectionHeader
		icon: icon
		name: name
	dom.append child
	return dom

lib.slider = ({
	name = 'slider'
	icon = 'fa-smile-o'
	object = {n:0}
	property = 'n'
	min
	max
	step

	onInput
	onChange
	display = (v) -> v
	transform = (v) -> v
}) ->
	# DOM
	slider = $ template.slider
	span = @spanText name
	label = @itemLabel 'sliderLabel' , [
		@icon(icon).addClass('fa-fw')
		span
	]
	# PROP
	if min? then slider.prop 'min' , min
	if max? then slider.prop 'max' , max
	if step? then slider.prop 'step' , step
	slider.prop 'value' , object[property]
	# change target values
	slider.on 'input change' , ->
		object[property] = transform parseFloat this.value
	# span.text change
	slider.on 'input' , -> span.text display transform parseFloat this.value
	slider.on 'mousedown' , ->
		lib.animate.sliderText
			dom: span
			callback: => span.text display transform parseFloat this.value
	slider.on 'mouseup' , ->
		lib.animate.sliderText
			dom: span
			reverse: true
			callback: => span.text name
	# events
	if onInput? then slider.on 'input' , (event) ->
		onInput.call this , (transform parseFloat this.value)
	if onChange? then slider.on 'change' , (event) ->
		onChange.call this , (transform parseFloat this.value)
	# return dom
	return @col 'sliderContainer' , [ label, slider ]

lib.display = ({
	name = 'display'
	icon = 'fa-smile-o'
	object
	property
	eventEmitter
	eventName
	eventNames
	display = (v)->v
})->
	label = @itemLabel 'displayLabel' , [
		if icon then @icon(icon).addClass('fa-fw')
		@spanText name
	]
	span = @spanText 'display' , ''
	update = (value) ->
		if value?
			span.text display value
		else if object? and property?
			span.text display object[property]
		else
			span.text display ''
	if eventEmitter?
		handler = ->
			if arguments.length > 0
				if name is arguments[0]
					update arguments[1]
			else
				update()
		if eventName then eventEmitter.on eventName , handler
		if eventNames
			eventNames.forEach (n) -> eventEmitter.on n , handler
	update()
	return @col 'displayContainer' , [ label , span ]

lib.button = ({
	id = undefined
	classes = undefined
	link = false
	name = 'button'
	icon = 'fa-smile-o'
	disabled = false
	action = ->
	solo = false
	group = undefined
	root = undefined
	checkbox = false
	checked = undefined
}) ->
	element = if link then @_aButton else @_button
	btn = element id , classes , [
		if icon then @icon icon
		@spanText name
	]
	btn.prop 'disabled' , disabled
	# Store Data
	btn.data 'ui' , {
		group: group
		solo: solo
		checkbox: checkbox
		checked: checked
		update: ( bool = false ) ->
			data.checked = bool
			btn.toggleClass 'checked' , bool
	}
	data = btn.data('ui')
	data.update checked
	# More
	# Checkbox
	if checkbox
		btn.click ->
			data.update solo or not data.checked
	# checkbox & group :
	# 1. when you are solo, when you activate, other activated buttons uncheck.
	# 2. when you are not solo, when you activate, other activated solos uncheck.
	if group and checkbox
		btn.click ->
			# only affect others when this is checked
			if data.checked is false then return
			others = root
				.find "button"
				# exclude self
				.not this
				# find members of my group
				.filter ->
					otherData = $(this).data('ui')
					if not otherData? then return false
					activated = otherData.checked
					mygroup = otherData.group is group
					return activated and mygroup
				# each
				.each ->
					other = $(this)
					otherData = other.data('ui')
					if solo or otherData.solo is true
						otherData.update false
	# Finally, user's action
	btn.click (e) ->
		if checkbox
			action.call( btn.get(0) , data.checked , btn , e )
		else
			action.call( btn.get(0) , btn , e )
	# return btn
	return btn

lib.toggle = ({
	name = 'toggle'
	icon
	action = ->
	checked = false
}) ->
	id = 'toggle' + ('0000000' + parseInt( Math.random() * 9999999999 )).slice(10)
	input = $( template.toggle ).prop( 'id' , id )
	label = @label id
	input.on 'change' , ->
		action( this.checked )
	input.get(0).checked = checked
	if checked then input.trigger 'change'
	return @col 'toggleContainer' , [
		@itemLabel [ (if icon then @icon(icon)) , name ]
		input
		label
	]

lib.option = (value,name = value) ->
	option = $ '<option />'
	option.prop 'value' , value
	option.text name
	return option

lib.select = ({
	name = 'untitled'
	options = []
	onInput = ->
	onChange = ->
}) ->
	select = $ '<select />'
	select.prop 'name' , name
	select.append @option o[1] , o[0] for o in options
	select.on 'input' , -> onInput this.value
	select.on 'change' , -> onChange this.value
	return select


module.exports = lib