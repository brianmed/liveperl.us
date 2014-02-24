package Mojo::DOM;
use Mojo::Base -strict;
use overload
  '@{}'    => sub { shift->contents },
  '%{}'    => sub { shift->attr },
  bool     => sub {1},
  '""'     => sub { shift->to_string },
  fallback => 1;

# "Fry: This snow is beautiful. I'm glad global warming never happened.
#  Leela: Actually, it did. But thank God nuclear winter canceled it out."
use Carp 'croak';
use List::Util 'first';
use Mojo::Collection;
use Mojo::DOM::CSS;
use Mojo::DOM::HTML;
use Mojo::Util qw(deprecated squish);
use Scalar::Util qw(blessed weaken);

sub AUTOLOAD {
  my $self = shift;

  my ($package, $method) = split /::(\w+)$/, our $AUTOLOAD;
  croak "Undefined subroutine &${package}::$method called"
    unless blessed $self && $self->isa(__PACKAGE__);

  # Search children of current element
  my $children = $self->children($method);
  return @$children > 1 ? $children : $children->[0] if @$children;
  croak qq{Can't locate object method "$method" via package "$package"};
}

sub DESTROY { }

sub all_contents { $_[0]->_collect(_all(_nodes($_[0]->tree))) }

sub all_text { shift->_all_text(1, @_) }

sub ancestors { _select($_[0]->_collect($_[0]->_ancestors), $_[1]) }

sub append { shift->_add(1, @_) }

sub append_content { shift->_content(1, 0, @_) }

sub at {
  my $self = shift;
  return undef unless my $result = $self->_css->select_one(@_);
  return _tag($self, $result, $self->xml);
}

sub attr {
  my $self = shift;

  # Hash
  my $tree = $self->tree;
  my $attrs = $tree->[0] ne 'tag' ? {} : $tree->[2];
  return $attrs unless @_;

  # Get
  return $attrs->{$_[0]} // '' unless @_ > 1 || ref $_[0];

  # Set
  %$attrs = (%$attrs, %{ref $_[0] ? $_[0] : {@_}});

  return $self;
}

sub children {
  my $self = shift;
  return _select(
    $self->_collect(grep { $_->[0] eq 'tag' } _nodes($self->tree)), @_);
}

sub content {
  my $self = shift;

  my $node = $self->node;
  if ($node eq 'root' || $node eq 'tag') {
    return $self->_content(0, 1, @_) if @_;
    my $html = Mojo::DOM::HTML->new(xml => $self->xml);
    return join '', map { $html->tree($_)->render } _nodes($self->tree);
  }

  return $self->tree->[1] unless @_;
  $self->tree->[1] = shift;
  return $self;
}

# DEPRECATED in Top Hat!
sub content_xml {
  deprecated
    'Mojo::DOM::content_xml is DEPRECATED in favor of Mojo::DOM::content';
  shift->content;
}

sub contents { $_[0]->_collect(_nodes($_[0]->tree)) }

sub find { $_[0]->_collect(@{$_[0]->_css->select($_[1])}) }

sub match { $_[0]->_css->match($_[1]) ? $_[0] : undef }

sub namespace {
  my $self = shift;

  return '' if (my $tree = $self->tree)->[0] ne 'tag';

  # Extract namespace prefix and search parents
  my $ns = $tree->[1] =~ /^(.*?):/ ? "xmlns:$1" : undef;
  for my $n ($tree, $self->_ancestors) {

    # Namespace for prefix
    my $attrs = $n->[2];
    if ($ns) { /^\Q$ns\E$/ and return $attrs->{$_} for keys %$attrs }

    # Namespace attribute
    elsif (defined $attrs->{xmlns}) { return $attrs->{xmlns} }
  }

  return '';
}

sub new {
  my $class = shift;
  my $self = bless \Mojo::DOM::HTML->new, ref $class || $class;
  return @_ ? $self->parse(@_) : $self;
}

sub next { shift->_siblings->[1][0] }
sub next_sibling { shift->_siblings(0, 1)->[1][0] }

sub node { shift->tree->[0] }

sub parent {
  my $self = shift;
  return undef if $self->tree->[0] eq 'root';
  return _tag($self, $self->_parent, $self->xml);
}

sub parse { shift->_delegate(parse => shift) }

sub prepend { shift->_add(0, @_) }

sub prepend_content { shift->_content(0, 0, @_) }

sub previous { shift->_siblings->[0][-1] }
sub previous_sibling { shift->_siblings(0, 1)->[0][-1] }

sub remove { shift->replace('') }

sub replace {
  my ($self, $new) = @_;
  return $self->parse($new) if (my $tree = $self->tree)->[0] eq 'root';
  return $self->_replace($self->_parent, $tree, $self->_parse("$new"));
}

# DEPRECATED in Top Hat!
sub replace_content {
  deprecated
    'Mojo::DOM::replace_content is DEPRECATED in favor of Mojo::DOM::content';
  shift->content(@_);
}

sub root {
  my $self = shift;
  return $self unless my $tree = $self->_ancestors(1);
  return _tag($self, $tree, $self->xml);
}

sub siblings { _select(Mojo::Collection->new(@{_siblings($_[0], 1)}), $_[1]) }

sub strip {
  my $self = shift;
  return $self if (my $tree = $self->tree)->[0] ne 'tag';
  return $self->_replace($tree->[3], $tree, ['root', _nodes($tree)]);
}

sub tap { shift->Mojo::Base::tap(@_) }

sub text { shift->_all_text(0, @_) }

# DEPRECATED in Top Hat!
sub text_after {
  deprecated
    'Mojo::DOM::text_after is DEPRECATED in favor of Mojo::DOM::contents';
  my ($self, $trim) = @_;

  return '' if (my $tree = $self->tree)->[0] ne 'tag';

  my (@nodes, $started);
  for my $n (_nodes($tree->[3])) {
    ++$started and next if $n eq $tree;
    next unless $started;
    last if $n->[0] eq 'tag';
    push @nodes, $n;
  }

  return _text(\@nodes, 0, _trim($tree->[3], $trim));
}

# DEPRECATED in Top Hat!
sub text_before {
  deprecated
    'Mojo::DOM::text_before is DEPRECATED in favor of Mojo::DOM::contents';
  my ($self, $trim) = @_;

  return '' if (my $tree = $self->tree)->[0] ne 'tag';

  my @nodes;
  for my $n (_nodes($tree->[3])) {
    last if $n eq $tree;
    @nodes = $n->[0] eq 'tag' ? () : (@nodes, $n);
  }

  return _text(\@nodes, 0, _trim($tree->[3], $trim));
}

sub to_string { shift->_delegate('render') }

# DEPRECATED in Top Hat!
sub to_xml {
  deprecated
    'Mojo::DOM::to_xml is DEPRECATED in favor of Mojo::DOM::to_string';
  shift->to_string;
}

sub tree { shift->_delegate(tree => @_) }

sub type {
  my ($self, $type) = @_;
  return '' if (my $tree = $self->tree)->[0] ne 'tag';
  return $tree->[1] unless $type;
  $tree->[1] = $type;
  return $self;
}

sub wrap         { shift->_wrap(0, @_) }
sub wrap_content { shift->_wrap(1, @_) }

sub xml { shift->_delegate(xml => @_) }

sub _add {
  my ($self, $offset, $new) = @_;

  return $self if (my $tree = $self->tree)->[0] eq 'root';

  my $parent = $self->_parent;
  splice @$parent, _offset($parent, $tree) + $offset, 0,
    _link($self->_parse("$new"), $parent);

  return $self;
}

sub _all {
  map { $_->[0] eq 'tag' ? ($_, _all(_nodes($_))) : ($_) } @_;
}

sub _all_text {
  my $tree = shift->tree;
  return _text([_nodes($tree)], shift, _trim($tree, @_));
}

sub _ancestors {
  my ($self, $root) = @_;

  return if $self->node eq 'root';

  my @ancestors;
  my $tree = $self->_parent;
  do { push @ancestors, $tree }
    while ($tree->[0] eq 'tag') && ($tree = $tree->[3]);
  return $root ? $ancestors[-1] : @ancestors[0 .. $#ancestors - 1];
}

sub _collect {
  my $self = shift;
  my $xml  = $self->xml;
  return Mojo::Collection->new(map { _tag($self, $_, $xml) } @_);
}

sub _content {
  my ($self, $start, $offset, $new) = @_;

  my $tree = $self->tree;
  unless ($tree->[0] eq 'root' || $tree->[0] eq 'tag') {
    my $old = $self->content;
    return $self->content($start ? "$old$new" : "$new$old");
  }

  $start  = $start  ? ($#$tree + 1) : _start($tree);
  $offset = $offset ? $#$tree       : 0;
  splice @$tree, $start, $offset, _link($self->_parse("$new"), $tree);

  return $self;
}

sub _css { Mojo::DOM::CSS->new(tree => shift->tree) }

sub _delegate {
  my ($self, $method) = (shift, shift);
  return $$self->$method unless @_;
  $$self->$method(@_);
  return $self;
}

sub _link {
  my ($children, $parent) = @_;

  # Link parent to children
  my @new;
  for my $n (@$children[1 .. $#$children]) {
    push @new, $n;
    my $offset = $n->[0] eq 'tag' ? 3 : 2;
    $n->[$offset] = $parent;
    weaken $n->[$offset];
  }

  return @new;
}

sub _nodes {
  return unless my $tree = shift;
  return @$tree[_start($tree) .. $#$tree];
}

sub _offset {
  my ($parent, $child) = @_;
  my $i = _start($parent);
  $_ eq $child ? last : $i++ for @$parent[$i .. $#$parent];
  return $i;
}

sub _parent { $_[0]->tree->[$_[0]->node eq 'tag' ? 3 : 2] }

sub _parse { Mojo::DOM::HTML->new(xml => shift->xml)->parse(shift)->tree }

sub _replace {
  my ($self, $parent, $tree, $new) = @_;
  splice @$parent, _offset($parent, $tree), 1, _link($new, $parent);
  return $self->parent;
}

sub _select {
  my ($collection, $selector) = @_;
  return $collection unless $selector;
  return $collection->new(grep { $_->match($selector) } @$collection);
}

sub _siblings {
  my ($self, $merge, $all) = @_;

  return $merge ? [] : [[], []] unless my $parent = $self->parent;

  my $tree = $self->tree;
  my (@before, @after, $match);
  for my $child ($parent->contents->each) {
    ++$match and next if $child->tree eq $tree;
    next unless $all || $child->node eq 'tag';
    $match ? push @after, $child : push @before, $child;
  }

  return $merge ? [@before, @after] : [\@before, \@after];
}

sub _start { $_[0][0] eq 'root' ? 1 : 4 }

sub _tag { $_[0]->new->tree($_[1])->xml($_[2]) }

sub _text {
  my ($nodes, $recurse, $trim) = @_;

  # Merge successive text nodes
  my $i = 0;
  while (my $next = $nodes->[$i + 1]) {
    ++$i and next unless $nodes->[$i][0] eq 'text' && $next->[0] eq 'text';
    splice @$nodes, $i, 2, ['text', $nodes->[$i][1] . $next->[1]];
  }

  my $text = '';
  for my $n (@$nodes) {
    my $type = $n->[0];

    # Nested tag
    my $content = '';
    if ($type eq 'tag' && $recurse) {
      $content = _text([_nodes($n)], 1, _trim($n, $trim));
    }

    # Text
    elsif ($type eq 'text') { $content = $trim ? squish($n->[1]) : $n->[1] }

    # CDATA or raw text
    elsif ($type eq 'cdata' || $type eq 'raw') { $content = $n->[1] }

    # Add leading whitespace if punctuation allows it
    $content = " $content" if $text =~ /\S\z/ && $content =~ /^[^.!?,;:\s]+/;

    # Trim whitespace blocks
    $text .= $content if $content =~ /\S+/ || !$trim;
  }

  return $text;
}

sub _trim {
  my ($n, $trim) = @_;

  # Disabled
  return 0 unless $n && ($trim = defined $trim ? $trim : 1);

  # Detect "pre" tag
  while ($n->[0] eq 'tag') {
    return 0 if $n->[1] eq 'pre';
    last unless $n = $n->[3];
  }

  return 1;
}

sub _wrap {
  my ($self, $content, $new) = @_;

  $content = 1 if (my $tree = $self->tree)->[0] eq 'root';
  $content = 0 if $tree->[0] ne 'root' && $tree->[0] ne 'tag';

  # Find innermost tag
  my $current;
  my $first = $new = $self->_parse("$new");
  $current = $first while $first = first { $_->[0] eq 'tag' } _nodes($first);
  return $self unless $current;

  # Wrap content
  if ($content) {
    push @$current, _link(['root', _nodes($tree)], $current);
    splice @$tree, _start($tree), $#$tree, _link($new, $tree);
    return $self;
  }

  # Wrap element
  $self->_replace($self->_parent, $tree, $new);
  push @$current, _link(['root', $tree], $current);
  return $self;
}

1;

=encoding utf8

=head1 NAME

Mojo::DOM - Minimalistic HTML/XML DOM parser with CSS selectors

=head1 SYNOPSIS

  use Mojo::DOM;

  # Parse
  my $dom = Mojo::DOM->new('<div><p id="a">A</p><p id="b">B</p></div>');

  # Find
  say $dom->at('#b')->text;
  say $dom->find('p')->text;
  say $dom->find('[id]')->attr('id');

  # Walk
  say $dom->div->p->[0]->text;
  say $dom->div->children('p')->first->{id};

  # Iterate
  $dom->find('p[id]')->each(sub { say shift->{id} });

  # Loop
  for my $e ($dom->find('p[id]')->each) {
    say $e->text;
  }

  # Modify
  $dom->div->p->last->append('<p id="c">C</p>');
  $dom->find(':not(p)')->strip;

  # Render
  say "$dom";

=head1 DESCRIPTION

L<Mojo::DOM> is a minimalistic and relaxed HTML/XML DOM parser with CSS
selector support. It will even try to interpret broken XML, so you should not
use it for validation.

=head1 CASE SENSITIVITY

L<Mojo::DOM> defaults to HTML semantics, that means all tags and attributes
are lowercased and selectors need to be lowercase as well.

  my $dom = Mojo::DOM->new('<P ID="greeting">Hi!</P>');
  say $dom->at('p')->text;
  say $dom->p->{id};

If XML processing instructions are found, the parser will automatically switch
into XML mode and everything becomes case sensitive.

  my $dom = Mojo::DOM->new('<?xml version="1.0"?><P ID="greeting">Hi!</P>');
  say $dom->at('P')->text;
  say $dom->P->{ID};

XML detection can also be disabled with the L</"xml"> method.

  # Force XML semantics
  $dom->xml(1);

  # Force HTML semantics
  $dom->xml(0);

=head1 METHODS

L<Mojo::DOM> implements the following methods.

=head2 all_contents

  my $collection = $dom->all_contents;

Return a L<Mojo::Collection> object containing all nodes in DOM structure as
L<Mojo::DOM> objects.

  # "<p><b>123</b></p>"
  $dom->parse('<p><!-- test --><b>123<!-- 456 --></b></p>')
    ->all_contents->grep(sub { $_->node eq 'comment' })->remove->first;

=head2 all_text

  my $trimmed   = $dom->all_text;
  my $untrimmed = $dom->all_text(0);

Extract all text content from DOM structure, smart whitespace trimming is
enabled by default.

  # "foo bar baz"
  $dom->parse("<div>foo\n<p>bar</p>baz\n</div>")->div->all_text;

  # "foo\nbarbaz\n"
  $dom->parse("<div>foo\n<p>bar</p>baz\n</div>")->div->all_text(0);

=head2 ancestors

  my $collection = $dom->ancestors;
  my $collection = $dom->ancestors('div > p');

Find all ancestors of this node matching the CSS selector and return a
L<Mojo::Collection> object containing these elements as L<Mojo::DOM> objects.
All selectors from L<Mojo::DOM::CSS/"SELECTORS"> are supported.

  # List types of ancestor elements
  say $dom->ancestors->type;

=head2 append

  $dom = $dom->append('<p>I ♥ Mojolicious!</p>');

Append HTML/XML fragment to this node.

  # "<div><h1>A</h1><h2>B</h2></div>"
  $dom->parse('<div><h1>A</h1></div>')->at('h1')->append('<h2>B</h2>')->root;

  # "<p>test 123</p>"
  $dom->parse('<p>test</p>')->at('p')->contents->first->append(' 123')->root;

=head2 append_content

  $dom = $dom->append_content('<p>I ♥ Mojolicious!</p>');

Append new content to this node's content.

  # "<div><h1>AB</h1></div>"
  $dom->parse('<div><h1>A</h1></div>')->at('h1')->append_content('B')->root;

  # "<!-- A B --><br>"
  $dom->parse('<!-- A --><br>')->contents->first->append_content('B ')->root;

=head2 at

  my $result = $dom->at('html title');

Find first element in DOM structure matching the CSS selector and return it as
a L<Mojo::DOM> object or return C<undef> if none could be found. All selectors
from L<Mojo::DOM::CSS/"SELECTORS"> are supported.

  # Find first element with "svg" namespace definition
  my $namespace = $dom->at('[xmlns\:svg]')->{'xmlns:svg'};

=head2 attr

  my $attrs = $dom->attr;
  my $foo   = $dom->attr('foo');
  $dom      = $dom->attr({foo => 'bar'});
  $dom      = $dom->attr(foo => 'bar');

This element's attributes.

  # List id attributes
  say $dom->find('*')->attr('id')->compact;

=head2 children

  my $collection = $dom->children;
  my $collection = $dom->children('div > p');

Find all children of this element matching the CSS selector and return a
L<Mojo::Collection> object containing these elements as L<Mojo::DOM> objects.
All selectors from L<Mojo::DOM::CSS/"SELECTORS"> are supported.

  # Show type of random child element
  say $dom->children->shuffle->first->type;

=head2 content

  my $str = $dom->content;
  $dom    = $dom->content('<p>I ♥ Mojolicious!</p>');

Return this node's content or replace it with new content.

  # "<b>test</b>"
  $dom->parse('<div><b>test</b></div>')->div->content;

  # "<div><h1>B</h1></div>"
  $dom->parse('<div><h1>A</h1></div>')->at('h1')->content('B')->root;

  # "<div><h1></h1></div>"
  $dom->parse('<div><h1>A</h1></div>')->at('h1')->content('')->root;

  # " A "
  $dom->parse('<!-- A --><br>')->contents->first->content;

  # "<!-- B --><br>"
  $dom->parse('<!-- A --><br>')->contents->first->content(' B ')->root;

=head2 contents

  my $collection = $dom->contents;

Return a L<Mojo::Collection> object containing the child nodes of this element
as L<Mojo::DOM> objects.

  # "<p><b>123</b></p>"
  $dom->parse('<p>test<b>123</b></p>')->at('p')->contents->first->remove;

  # "<!-- test -->"
  $dom->parse('<!-- test --><b>123</b>')->contents->first;

=head2 find

  my $collection = $dom->find('html title');

Find all elements in DOM structure matching the CSS selector and return a
L<Mojo::Collection> object containing these elements as L<Mojo::DOM> objects.
All selectors from L<Mojo::DOM::CSS/"SELECTORS"> are supported.

  # Find a specific element and extract information
  my $id = $dom->find('div')->[23]{id};

  # Extract information from multiple elements
  my @headers = $dom->find('h1, h2, h3')->text->each;
  my @links   = $dom->find('a[href]')->attr('href')->each;

=head2 match

  my $result = $dom->match('html title');

Match the CSS selector against this element and return it as a L<Mojo::DOM>
object or return C<undef> if it didn't match. All selectors from
L<Mojo::DOM::CSS/"SELECTORS"> are supported.

=head2 namespace

  my $namespace = $dom->namespace;

Find this element's namespace.

  # Find namespace for an element with namespace prefix
  my $namespace = $dom->at('svg > svg\:circle')->namespace;

  # Find namespace for an element that may or may not have a namespace prefix
  my $namespace = $dom->at('svg > circle')->namespace;

=head2 new

  my $dom = Mojo::DOM->new;
  my $dom = Mojo::DOM->new('<foo bar="baz">I ♥ Mojolicious!</foo>');

Construct a new scalar-based L<Mojo::DOM> object and L</"parse"> HTML/XML
fragment if necessary.

=head2 next

  my $sibling = $dom->next;

Return L<Mojo::DOM> object for next sibling element or C<undef> if there are
no more siblings.

  # "<h2>B</h2>"
  $dom->parse('<div><h1>A</h1><h2>B</h2></div>')->at('h1')->next;

=head2 next_sibling

  my $sibling = $dom->next_sibling;

Return L<Mojo::DOM> object for next sibling node or C<undef> if there are no
more siblings.

  # "456"
  $dom->parse('<p><b>123</b><!-- test -->456</p>')->at('b')
    ->next_sibling->next_sibling;

=head2 node

  my $type = $dom->node;

This node's type, usually C<cdata>, C<comment>, C<doctype>, C<pi>, C<raw>,
C<root>, C<tag> or C<text>.

=head2 parent

  my $parent = $dom->parent;

Return L<Mojo::DOM> object for parent of this node or C<undef> if this node
has no parent.

=head2 parse

  $dom = $dom->parse('<foo bar="baz">I ♥ Mojolicious!</foo>');

Parse HTML/XML fragment with L<Mojo::DOM::HTML>.

  # Parse XML
  my $dom = Mojo::DOM->new->xml(1)->parse($xml);

=head2 prepend

  $dom = $dom->prepend('<p>I ♥ Mojolicious!</p>');

Prepend HTML/XML fragment to this node.

  # "<div><h1>A</h1><h2>B</h2></div>"
  $dom->parse('<div><h2>B</h2></div>')->at('h2')->prepend('<h1>A</h1>')->root;

  # "<p>test 123</p>"
  $dom->parse('<p>123</p>')->at('p')->contents->first->prepend('test ')->root;

=head2 prepend_content

  $dom = $dom->prepend_content('<p>I ♥ Mojolicious!</p>');

Prepend new content to this node's content.

  # "<div><h2>AB</h2></div>"
  $dom->parse('<div><h2>B</h2></div>')->at('h2')->prepend_content('A')->root;

  # "<!-- A B --><br>"
  $dom->parse('<!-- B --><br>')->contents->first->prepend_content(' A')->root;

=head2 previous

  my $sibling = $dom->previous;

Return L<Mojo::DOM> object for previous sibling element or C<undef> if there
are no more siblings.

  # "<h1>A</h1>"
  $dom->parse('<div><h1>A</h1><h2>B</h2></div>')->at('h2')->previous;

=head2 previous_sibling

  my $sibling = $dom->previous_sibling;

Return L<Mojo::DOM> object for previous sibling node or C<undef> if there are
no more siblings.

  # "123"
  $dom->parse('<p>123<!-- test --><b>456</b></p>')->at('b')
    ->previous_sibling->previous_sibling;

=head2 remove

  my $parent = $dom->remove;

Remove this node and return L</"parent">.

  # "<div></div>"
  $dom->parse('<div><h1>A</h1></div>')->at('h1')->remove;

  # "<p><b>456</b></p>"
  $dom->parse('<p>123<b>456</b></p>')->at('p')->contents->first->remove->root;

=head2 replace

  my $parent = $dom->replace('<div>I ♥ Mojolicious!</div>');

Replace this node with HTML/XML fragment and return L</"parent">.

  # "<div><h2>B</h2></div>"
  $dom->parse('<div><h1>A</h1></div>')->at('h1')->replace('<h2>B</h2>');

  # "<p><b>B</b></p>"
  $dom->parse('<p>A</p>')->at('p')->contents->[0]->replace('<b>B</b>')->root;

=head2 root

  my $root = $dom->root;

Return L<Mojo::DOM> object for root node.

=head2 siblings

  my $collection = $dom->siblings;
  my $collection = $dom->siblings('div > p');

Find all sibling elements of this node matching the CSS selector and return a
L<Mojo::Collection> object containing these elements as L<Mojo::DOM> objects.
All selectors from L<Mojo::DOM::CSS/"SELECTORS"> are supported.

  # List types of sibling elements
  say $dom->siblings->type;

=head2 strip

  my $parent = $dom->strip;

Remove this element while preserving its content and return L</"parent">.

  # "<div>A</div>"
  $dom->parse('<div><h1>A</h1></div>')->at('h1')->strip;

=head2 tap

  $dom = $dom->tap(sub {...});

Alias for L<Mojo::Base/"tap">.

=head2 text

  my $trimmed   = $dom->text;
  my $untrimmed = $dom->text(0);

Extract text content from this element only (not including child elements),
smart whitespace trimming is enabled by default.

  # "foo baz"
  $dom->parse("<div>foo\n<p>bar</p>baz\n</div>")->div->text;

  # "foo\nbaz\n"
  $dom->parse("<div>foo\n<p>bar</p>baz\n</div>")->div->text(0);

=head2 to_string

  my $str = $dom->to_string;

Render this node and its content to HTML/XML.

  # "<b>test</b>"
  $dom->parse('<div><b>test</b></div>')->div->b->to_string;

=head2 tree

  my $tree = $dom->tree;
  $dom     = $dom->tree(['root', ['text', 'foo']]);

Document Object Model. Note that this structure should only be used very
carefully since it is very dynamic.

=head2 type

  my $type = $dom->type;
  $dom     = $dom->type('div');

This element's type.

  # List types of child elements
  say $dom->children->type;

=head2 wrap

  $dom = $dom->wrap('<div></div>');

Wrap HTML/XML fragment around this node, placing it as the last child of the
first innermost element.

  # "<p>B<b>A</b></p>"
  $dom->parse('<b>A</b>')->at('b')->wrap('<p>B</p>')->root;

  # "<div><p><b>A</b></p>B</div>"
  $dom->parse('<b>A</b>')->at('b')->wrap('<div><p></p>B</div>')->root;

  # "<p><b>A</b></p><p>B</p>"
  $dom->parse('<b>A</b>')->at('b')->wrap('<p></p><p>B</p>')->root;

  # "<p><b>A</b></p>"
  $dom->parse('<p>A</p>')->at('p')->contents->first->wrap('<b>')->root;

=head2 wrap_content

  $dom = $dom->wrap_content('<div></div>');

Wrap HTML/XML fragment around this node's content, placing it as the last
children of the first innermost element.

  # "<p><b>BA</b></p>"
  $dom->parse('<p>A<p>')->at('p')->wrap_content('<b>B</b>')->root;

  # "<p><b>A</b></p><p>B</p>"
  $dom->parse('<b>A</b>')->wrap_content('<p></p><p>B</p>');

=head2 xml

  my $bool = $dom->xml;
  $dom     = $dom->xml($bool);

Disable HTML semantics in parser and activate case sensitivity, defaults to
auto detection based on processing instructions.

=head1 AUTOLOAD

In addition to the L</"METHODS"> above, many child elements are also
automatically available as object methods, which return a L<Mojo::DOM> or
L<Mojo::Collection> object, depending on number of children. For more power
and consistent results you can also use L</"children">.

  say $dom->p->text;
  say $dom->div->[23]->text;
  say $dom->div->text;

=head1 OPERATORS

L<Mojo::DOM> overloads the following operators.

=head2 array

  my @nodes = @$dom;

Alias for L</"contents">.

  # "<!-- test -->"
  $dom->parse('<!-- test --><b>123</b>')->[0];

=head2 bool

  my $bool = !!$dom;

Always true.

=head2 hash

  my %attrs = %$dom;

Alias for L</"attr">.

  # "test"
  $dom->parse('<div id="test">A</div>')->at('div')->{id};

=head2 stringify

  my $str = "$dom";

Alias for L</"to_string">.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
