{$, $$, View, ScrollView} = require 'atom-space-pen-views'
{Emitter} = require 'event-kit'

module.exports =
  TreeNode: class TreeNode extends View
    @content: ({label, icon, loaded, children, type}) ->
      if children
        @li class: 'list-nested-item list-selectable-item collapsed', =>
          @div class: 'list-item', =>
            @span class: "icon #{icon} #{type}", label
          @ul class: 'list-tree', outlet: 'children', =>
            for child in children
              @subview 'child', new TreeNode(child)
      else if not loaded
        @li class: 'list-nested-item list-selectable-item collapsed', =>
            @div class: 'list-item', =>
                @span class: "icon #{icon} #{type}", label
            @ul class: 'list-tree', outlet: 'children'
      else
          @li class: 'list-item list-selectable-item', =>
              @span class: "icon #{icon} #{type}", label

    initialize: (item) ->
      @emitter = new Emitter
      @item = item
      @item.view = this

      @on 'dblclick', @dblClickItem
      @on 'click', @clickItem

    setChildren: (children) ->
        @children.empty()
        @item.children = children
        content = $$ ->
            @div =>
                for child in children
                    @subview 'child', new TreeNode(child)
        @children.append(content.children())

    addChild: (child) ->
        @item.children.push(child)
        content = $$ ->
            @div => @subview 'child', new TreeNode(child)
        @children.append(content.children())

    setCollapsed: ->
      @toggleClass('collapsed') if @item.children

    setSelected: ->
      @addClass('selected')

    onDblClick: (callback) ->
      @emitter.on 'on-dbl-click', callback
      if @item.children
        for child in @item.children
          child.view.onDblClick callback

    onSelect: (callback) ->
      @emitter.on 'on-select', callback
      if @item.children
        for child in @item.children
          child.view.onSelect callback

    clickItem: (event) =>
      if @item.children
        selected = @hasClass('selected')
        @removeClass('selected')
        $target = @find('.list-item:first')
        left = $target.position().left
        right = $target.children('span').position().left
        width = right - left
        @toggleClass('collapsed') if event.offsetX <= width
        @addClass('selected') if selected
        return false if event.offsetX <= width

      @emitter.emit 'on-select', {node: this, item: @item}
      return false

    dblClickItem: (event) =>
      @emitter.emit 'on-dbl-click', {node: this, item: @item}
      return false


  TreeView: class TreeView extends ScrollView
    @content: ->
        @div class: 'existdb-tree-view-resizer tool-panel focusable-panel', 'data-show-on-right-side': !atom.config.get('tree-view.showOnRightSide'), =>
            @div class: 'tree-view-scroller order--center', =>
                @ul class: 'existdb-tree-view list-tree has-collapsable-children', outlet: 'root'
            @div class: 'tree-view-resize-handle', outlet: 'resizeHandle'

    initialize: ->
      super
      @emitter = new Emitter
      @on 'mousedown', '.tree-view-resize-handle', (e) => @resizeStarted(e)

    deactivate: ->
      @remove()

    onSelect: (callback) =>
      @emitter.on 'on-select', callback

    setRoot: (root, ignoreRoot=true) ->
      @rootNode = new TreeNode(root)
      root.view = @rootNode
      @rootNode.setCollapsed()
      @rootNode.onDblClick ({node, item}) =>
        node.setCollapsed()
      @rootNode.onSelect ({node, item}) =>
        @clearSelect()
        node.setSelected()
        @emitter.emit 'on-select', {node, item}

      @root.empty()
      @root.append $$ ->
        @div =>
          if ignoreRoot
            for child in root.children
              @subview 'child', child.view
          else
            @subview 'root', root.view

    traversal: (root, doing) =>
      doing(root.item)
      if root.item.children
        for child in root.item.children
          @traversal(child.view, doing)

    toggleTypeVisible: (type) =>
      @traversal @rootNode, (item) =>
        if item.type == type
          item.view.toggle()

    sortByName: (ascending=true) =>
      @traversal @rootNode, (item) =>
        item.children?.sort (a, b) =>
          if ascending
            return a.name.localeCompare(b.name)
          else
            return b.name.localeCompare(a.name)
      @setRoot(@rootNode.item)

    sortByRow: (ascending=true) =>
      @traversal @rootNode, (item) =>
        item.children?.sort (a, b) =>
          if ascending
            return a.position.row - b.position.row
          else
            return b.position.row - a.position.row
      @setRoot(@rootNode.item)

    clearSelect: ->
      $('.list-selectable-item').removeClass('selected')

    select: (item) ->
      @clearSelect()
      item?.view.setSelected()

    resizeStarted: =>
        $(document).on('mousemove', @resizeTreeView)
        $(document).on('mouseup', @resizeStopped)

    resizeStopped: =>
        $(document).off('mousemove', @resizeTreeView)
        $(document).off('mouseup', @resizeStopped)

    resizeTreeView: ({pageX, which}) =>
        return @resizeStopped() unless which is 1

        if atom.config.get('tree-view.showOnRightSide')
            width = pageX - @offset().left
        else
            width = @outerWidth() + @offset().left - pageX
        @width(width)
