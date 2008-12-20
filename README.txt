= dslify

== DESCRIPTION:

  Easily add DSL accessors to any class without bothering to mess with the gory details of their implementation

== SYNOPSIS:

  Simply add Dslify to your class, like so:
    class MyClass
      include Dslify
    end
    
  Then, you can call *any* method on your object and, if it is not a method on the instance, it will set the value on the class as an option. Note, you can always check these by checking out the options on the object. 
    
    instance = MyClass.new
    instance.name #=> nil
    instance.name "frank"
    instance.name #=> "frank"
    
  You can also define default values with the singleton method:
    default_options({:name => "bob"})
    
    instance = MyClass.new
    instance.name #=> "bob"
    instance.name "frank"
    instance.name #=> "frank"

== REQUIREMENTS:

  ruby

== INSTALL:

  sudo gem install auser-dslify

== LICENSE:

(The MIT License)

Copyright (c) 2008 Ari Lerner

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.