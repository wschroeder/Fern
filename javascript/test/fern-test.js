var buster = require("buster");
eval(require('fs').readFileSync('lib/Fern.js', 'utf8'));

var render_tag_and_metadata = Fern.render_tag_and_metadata;
var render_tag              = Fern.render_tag;
var empty_element_tag       = Fern.empty_element_tag;
var tag                     = Fern.tag;

buster.testCase("Fern", {
    "Empty HTML tag elements": function () {
        for (var tag_name in ['br', 'hr', 'input']) {
            assert.equals(
                empty_element_tag(tag_name)(),
                ['<' + tag_name + ' />'],
                tag_name
            );
        }
    },
    "Normal HTML tag elements": function () {
        for (var tag_name in [
                'a', 'abbr', 'acronym', 'address', 'area', 'b', 'base', 'bdo',
                'big', 'blockquote', 'body', 'button', 'caption', 'cite',
                'code', 'col', 'colgroup', 'dd', 'del', 'div', 'dfn', 'dl',
                'dt', 'em', 'fieldset', 'form', 'h1', 'h2', 'h3', 'h4', 'h5',
                'h6', 'head', 'html', 'i', 'img', 'ins', 'kbd', 'label',
                'legend', 'li', 'link', 'map', 'meta', 'noscript', 'object',
                'ol', 'optgroup', 'option', 'p', 'param', 'pre', 'q', 'samp',
                'script', 'select', 'small', 'span', 'strong', 'style', 'sub',
                'sup', 'table', 'tbody', 'td', 'textarea', 'tfoot', 'th',
                'thead', 'title', 'tr', 'tt', 'ul', 'var']) {
            assert.equals(
                tag(tag_name)(),
                ['<' + tag_name + '></' + tag_name + '>'],
                tag_name
            );
        }
    },
    "Attributes": function () {
        assert.equals(
            render_tag(tag('div', {random: 'lala'})),
            '<div random="lala"></div>'
        );
    },
    "Containment": function () {
        assert.equals(
            render_tag(tag('div', {class: 'foo'}, tag('div', {class: 'bar'}, tag('div')))),
            '<div class="foo"><div class="bar"><div></div></div></div>'
        );
    },
    "Ordered attributes": function () {
        assert.equals(
            render_tag(tag('div', ['class', 'foo', 'name', 'foofoo'], 'Test')),
            '<div class="foo" name="foofoo">Test</div>'
        );
    },
    "Complex example": function () {
        var got = render_tag(
            tag('div', {class: 'modal hide fade imp-error-modal'},
                tag('div', {class: 'modal-header'},
                    tag('button', ['type', 'button', 'class', 'close', 'data-dismiss', 'modal'], '×'),
                      tag('h3', 'A JavaScript error has occurred')),
                  tag('div', {class: 'modal-body'},
                    tag('p', "Please click the &quot;Open RT&quot; button to open an RT window and submit the error.",
                        "Add to the ticket how we can reproduce this error."),
                      tag('h4', 'Error Info'),
                      tag('pre', 'info')),
                  tag('div', {class: 'modal-footer'},
                    tag('a', ['href', '#', 'class', 'btn', 'data-dismiss', 'modal'],
                        'Ignore'),
                      tag('a', ['href', '#', 'class', 'btn btn-primary'],
                        'Open RT')))
        );

        var expected = '<div class="modal hide fade imp-error-modal"><div class="modal-header"><button type="button" class="close" data-dismiss="modal">×</button><h3>A JavaScript error has occurred</h3></div><div class="modal-body"><p>Please click the &quot;Open RT&quot; button to open an RT window and submit the error.Add to the ticket how we can reproduce this error.</p><h4>Error Info</h4><pre>info</pre></div><div class="modal-footer"><a href="#" class="btn" data-dismiss="modal">Ignore</a><a href="#" class="btn btn-primary">Open RT</a></div></div>';
        assert.equals(got, expected);
    },
    "foo tag (not empty-element tag)": function () {
        assert.equals(render_tag(tag('foo')), '<foo></foo>');
    },
    "foo tag (not empty-element tag)": function () {
        assert.equals(render_tag(tag('foo')), '<foo></foo>');
    },
    "bar tag (empty-element tag)": function () {
        assert.equals(render_tag(empty_element_tag('bar')), '<bar />');
    },
    "custom tag": function () {
        function custom_tag (obj, p1, p2) {
            return function () {
                return [
                    render_tag(
                        tag('span', 'Class (' + obj.class + ') and Param 1 (' + p1 + ') and Param 2 (' + p2 + ')'),
                        Array.prototype.slice.call(arguments, 0)
                    ),
                    {metadata: 5}
                ];
            };
        }

        var custom_tag_function = tag('div', custom_tag({class: 'this-class'}, 3, 'test'));
        assert.equals(
            render_tag(custom_tag_function),
            '<div><span>Class (this-class) and Param 1 (3) and Param 2 (test)</span></div>',
            'XML'
        );
        assert.equals(custom_tag_function()[1].metadata, 5, 'Metadata');
    },
    "metadata": function () {
        var tag_function = tag('div',
                               tag('span',
                                   function (param1) { return [param1, 'apple']; },
                                   ' and ',
                                   function (param1, param2) { return [param2, 'banana']; }));
        var content_and_metadata = tag_function('foo', 4);
        var xml = content_and_metadata[0];
        var m1  = content_and_metadata[1];
        var m2  = content_and_metadata[2];
        assert.equals(xml, '<div><span>foo and 4</span></div>', 'Metadata-filled xml');
        assert.equals(m1, 'apple', 'Metadata trickle 1');
        assert.equals(m2, 'banana', 'Metadata trickle 2');
    },
    "Dynamic tag tree 1": function () {
        assert.equals(
            render_tag(tag('div', (1 == 1 ? tag('div') : tag('span')))),
            '<div><div></div></div>'
        );
    },
    "Dynamic tag tree 2": function () {
        assert.equals(
            render_tag(tag('div', (1 == 0 ? tag('div') : tag('span')))),
            '<div><span></span></div>'
        );
    },
    "Parameter passing in content": function () {
        var template1 = tag('div',
                             tag('span',
                                 function () { return [arguments[0]] }),
                             tag('span',
                                 function () { return [arguments[1]] }));
        assert.equals(
            template1('Hello', 'World')[0],
            '<div><span>Hello</span><span>World</span></div>'
        );
    },
    "Parameter passing in tags": function () {
        var template2 = empty_element_tag('div', { fruit: function (fruit_value) { return [fruit_value] } });
        assert.equals(
            template2('apple', 'number')[0],
            '<div fruit="apple" />'
        );
    }
});

