import 'package:flutter/material.dart';

const List<String> _fontFamilies = [
  'Roboto',
  'Times New Roman',
  'Arial',
  'Helvetica',
  'Verdana',
  'Georgia',
];

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    ),
    home: const TextCanvasScreen(),
  ));
}

class TextCanvasScreen extends StatefulWidget {
  const TextCanvasScreen({Key? key}) : super(key: key);
  @override
  _TextCanvasScreenState createState() => _TextCanvasScreenState();
}

class _TextCanvasScreenState extends State<TextCanvasScreen> {
  final List<_MovableText> _texts = [];
  final List<List<_MovableText>> _history = [];
  final List<List<_MovableText>> _redoStack = [];
  final TextEditingController _textController = TextEditingController();
  _MovableText? _selectedText;
  bool _isEditPanelVisible = false;
  bool _isEditing = false; // Tracks whether we are in edit mode.
  double _bottomPanelHeight = 350;
  final double _minPanelHeight = 100;
  final double _maxPanelHeight = 500;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (_isEditing && _selectedText != null) {
        setState(() {
          _selectedText!.text = _textController.text;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Canvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _history.isEmpty ? null : _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redoStack.isEmpty ? null : _redo,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _selectedText != null ? _enterEditMode : null,
            tooltip: 'Edit Selected Text',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _selectedText != null ? _deleteSelected : null,
            tooltip: 'Delete Selected',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildCanvas(),
          if (_isEditPanelVisible) _buildBottomPanel(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addText,
        child: const Icon(Icons.text_fields),
      ),
    );
  }

  Widget _buildCanvas() {
    return GestureDetector(
      onTap: () {
        setState(() {
          for (var text in _texts) {
            text.isSelected = false;
          }
          _selectedText = null;
          _isEditPanelVisible = false;
          _isEditing = false; // Exit edit mode if canvas is tapped
        });
      },
      child: Container(
        color: Colors.grey[100],
        child: Stack(
          children: _texts.map((text) {
            return Positioned(
              left: text.offset.dx,
              top: text.offset.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!_isEditing) {
                    _selectText(text);
                  }
                },
                onPanStart: (details) {
                  _addToHistory();
                  if (!_isEditing) {
                    _selectText(text);
                  }
                },
                onPanUpdate: (details) {
                  setState(() {
                    text.offset += details.delta;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: text.isSelected
                        ? Border.all(color: Colors.blue, width: 1)
                        : null,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    text.text,
                    style: TextStyle(
                      fontSize: text.fontSize,
                      fontWeight: text.fontWeight,
                      color: text.color,
                      fontFamily: text.fontFamily,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _bottomPanelHeight = (_bottomPanelHeight - details.delta.dy)
                    .clamp(_minPanelHeight, _maxPanelHeight);
              });
            },
            child: Container(
              height: 24,
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          if (_isEditing)
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save Changes'),
            ),
          Container(
            height: _bottomPanelHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing)
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'Text',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text('Font Size: ${_selectedText?.fontSize.round()}'),
                  Slider(
                    value: _selectedText?.fontSize ?? 16,
                    min: 8,
                    max: 72,
                    divisions: 64,
                    label: '${_selectedText?.fontSize.round()}',
                    onChanged: _isEditing
                        ? (value) {
                            setState(() {
                              if (_selectedText != null) {
                                _selectedText!.fontSize = value;
                              }
                            });
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Font Family'),
                  Wrap(
                    spacing: 8,
                    children: _fontFamilies
                        .map((font) => ChoiceChip(
                              label: Text(font,
                                  style: TextStyle(fontFamily: font)),
                              selected: _selectedText?.fontFamily == font,
                              onSelected: _isEditing
                                  ? (selected) {
                                      if (selected && _selectedText != null) {
                                        setState(() {
                                          _selectedText!.fontFamily = font;
                                        });
                                      }
                                    }
                                  : null,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Text Color'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Colors.black,
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                    ].map((color) {
                      return GestureDetector(
                        onTap: _isEditing
                            ? () {
                                setState(() {
                                  if (_selectedText != null) {
                                    _selectedText!.color = color;
                                  }
                                });
                              }
                            : null,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: _selectedText?.color == color
                                  ? Colors.blue
                                  : Colors.grey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToHistory() {
    final currentState = _texts.map((e) => e.copy()).toList();
    _history.add(currentState);
    _redoStack.clear();
  }

  void _addText() {
    setState(() {
      _addToHistory();
      final size = MediaQuery.of(context).size;
      final newText = _MovableText(
        text: "New Text",
        offset: Offset(size.width / 2 - 50, size.height / 2 - 50),
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.black,
      );
      _texts.add(newText);
      _selectText(newText);
    });
  }

  void _enterEditMode() {
    setState(() {
      if (_selectedText != null) {
        _isEditing = true;
        _textController.text = _selectedText!.text;
        _isEditPanelVisible = true;
      }
    });
  }

  void _saveChanges() {
    setState(() {
      _isEditing = false;
      _isEditPanelVisible = false;
    });
  }

  void _selectText(_MovableText text) {
    setState(() {
      for (var t in _texts) {
        t.isSelected = (t == text);
      }
      _selectedText = text;
      _isEditPanelVisible = true;
    });
  }

  void _undo() {
    if (_history.isNotEmpty) {
      setState(() {
        final currentState = _texts.map((e) => e.copy()).toList();
        _redoStack.add(currentState);
        _texts.clear();
        _texts.addAll(_history.removeLast());
        _selectedText = null;
        _isEditPanelVisible = false;
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        final currentState = _texts.map((e) => e.copy()).toList();
        _history.add(currentState);
        _texts.clear();
        _texts.addAll(_redoStack.removeLast());
        _selectedText = null;
        _isEditPanelVisible = false;
      });
    }
  }

  void _deleteSelected() {
    if (_selectedText != null) {
      setState(() {
        _addToHistory();
        _texts.remove(_selectedText);
        _selectedText = null;
        _isEditPanelVisible = false;
      });
    }
  }
}

class _MovableText {
  String text;
  Offset offset;
  double fontSize;
  FontWeight fontWeight;
  Color color;
  String fontFamily;
  bool isSelected;

  _MovableText({
    required this.text,
    required this.offset,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    this.fontFamily = 'Roboto',
    this.isSelected = false,
  });

  _MovableText copy() {
    return _MovableText(
      text: text,
      offset: offset,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: fontFamily,
      isSelected: isSelected,
    );
  }
}
