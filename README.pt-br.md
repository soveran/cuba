Cuba
====

_n_. um microframework para desenvolvimento web.

![Cuba and Rum, by Jan Sochor](http://farm3.static.flickr.com/2619/4032103097_8324c6fecf.jpg)

Comunidade
---------

Nos encontre no IRC: [#cuba.rb](irc://chat.freenode.net/#cuba.rb) na [freenode.net](http://freenode.net/)

Descrição
-----------

Cuba é um microframework para desenvolvimento web originalmente inspirado pelo [Rum][rum], um pequeno mas poderoso mapper para aplicações [Rack][rack].

Ele integra vários _templates_ por meio do [Tilt][tilt]. Os testes são por meio do [Cutest][cutest] e [Capybara][capybara].

[rum]: http://github.com/chneukirchen/rum
[rack]: http://github.com/chneukirchen/rack
[tilt]: http://github.com/rtomayko/tilt
[cutest]: http://github.com/djanowski/cutest
[capybara]: http://github.com/jnicklas/capybara
[rack-test]: https://github.com/brynary/rack-test

Uso
-----

Uma simples aplicação:

``` ruby
# cat ola_mundo.rb
require "cuba"

Cuba.use Rack::Session::Cookie

Cuba.define do
  on get do
    on "ola" do
      res.write "Olá mundo!"
    end

    on root do
      res.redirect "/ola"
    end
  end
end

# cat ola_mundo_test.rb
require "cuba/test"

scope do
  test "Página inicial" do
    get "/"

    follow_redirect!

    assert_equal "Olá mundo!", last_response.body
  end
end
```

Para rodar, você pode criar um arquivo `config.ru`:

``` ruby
# cat config.ru
require "./ola_mundo"

run Cuba
```

Agora, rode o comando `rackup` para ver sua aplicação rodando.

Matchers
--------

Um exemplo mostrando como matchers diferentes podem trabalhar:

``` ruby
require "cuba"

Cuba.use Rack::Session::Cookie

Cuba.define do

  # somente requisições GET
  on get do

    # /
    on root do
      res.write "Início"
    end

    # /sobre
    on "sobre" do
      res.write "Sobre"
    end

    # /estilos/basico.css
    on "estilos", extension("css") do |file|
      res.write "Nome do arquivo: #{file}" #=> "Nome do arquivo: basico"
    end

    # /post/2011/02/16/ola
    on "post/:y/:m/:d/:slug" do |y, m, d, slug|
      res.write "#{y}-#{m}-#{d} #{slug}" #=> "2011-02-16 ola"
    end

    # /usuario/foobar
    on "usuario/:usuario" do |usuario|
      usuario = Usuario.find_by_usuario(usuario) # usuario == "foobar"

      # /usuario/foobar/posts
      on "posts" do

        # Você pode acessar o objeto `usuario` aqui, pois ainda está
        # dentro do bloco.
        res.write "Total de posts: #{usuario.posts.size}" #=> "Total de posts: 6"
      end

      # /usuario/foobar/seguindo
      on "seguindo" do
        res.write usuario.seguindo.size #=> "1301"
      end
    end

    # /pesquisa?c=barbaz
    on "pesquisa", param("c") do |condicao|
      res.write "Pesquisa por #{condicao}" #=> "Pesquisa por barbaz"
    end
  end

  # somente requisições POST
  on post do
    on "entrar" do

      # POST /entrar, usuario: foo, senha: baz
      on param("usuario"), param("senha") do |usuario, senha|
        res.write "#{usuario}:#{senha}" #=> "foo:baz"
      end

      # Se os parâmetros `usuario` e `senha` não são informados, este
      # bloco será executado.
      on true do
        res.write "Você precisa informar seu usuario e senha!"
      end
    end
  end
end
```

Segurança
--------

A camada de segurança do Cuba é a [Rack::Protection](https://github.com/rkh/rack-protection). Ela não está incluída por padrão, porque existem usos legítimos do Cuba, puro e simples (por exemplo, ao desenvolver uma API).

Se você está desenvolvendo uma aplicação web, certifique-se de incluir uma camada de segurança. Por convenção, apenas requisições POST, PUT e DELETE são monitoradas.

``` ruby
require "cuba"
require "rack/protection"

Cuba.use Rack::Session::Cookie
Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer

Cuba.define do

  # Agora, sua aplicação está protegida contra uma ampla variedade de ataques.
  ...
end
```

Verbos HTTP
----------

Exitem quatro matchers definidos para verbos HTTP: `get`, `post`, `put` e `delete`. Mas, não para por aí. Você tem a requisição total disponível através do objeto `req`, podendo consultá-lo com métodos auxiliares como `req.options?` ou `req.head?`, ou ainda pode ir um nível abaixo e inspecionar o ambiente com o objeto `env` e verificar, por exemplo, se `env["REQUEST_METHOD"]` é igual ao verbo `PATCH`.

Diferentes maneiras de dizer a mesma coisa:

``` ruby
on env["REQUEST_METHOD"] == "GET", "api" do ... end

on req.get?, "api" do ... end

on get, "api" do ... end
```

O `get` é apenas um _syntax sugar_ para `req.get?` que, por sua vez, é um _syntax sugar_ para `env["REQUEST_METHOD"] == "GET"`.

Requisição e resposta
--------------------

Percebe-se que usamos muito os objetos `req` e `res`. Essas variáveis são instâncias de [Rack::Request][request] e `Cuba::Response` respectivamente. `Cuba::Response` é apenas uma versão otimizada de [Rack::Response][response].

[request]: http://rack.rubyforge.org/doc/classes/Rack/Request.html
[response]: http://rack.rubyforge.org/doc/classes/Rack/Response.html

Esses objetos são _helpers_ para acessar a requisição e construir respostas. Na maior parte dos casos, você usará apenas `req.write`.

Se quiser, pode usar um objeto de requisição ou resposta personalizado, podendo definir novos valores da seguinte forma:

``` ruby
Cuba.settings[:req] = MinhaRequisicao
Cuba.settings[:res] = MinhaResposta
```

Certifique-se de informar classes compatíveis com as do Rack.

Capturas
--------

Você notou que alguns matchers podem produzir valores para um bloco. As regras para determinar se um matcher vai produzir valores é simples:

1. Captura por expressão regular: `"posts/(\\d+)-(.*)"` produzirá dois valores que correspondem a cada captura.
2. Espaços reservados: `"usuarios/:id"` produzirá um valor para a posição :id.
3. Símbolos: `:foobar` irá produzir um valor se um segmento estiver disponível.
4. Extensões de arquivos: `extension("css")` terá o nome do arquivo conforme a extensão.
5. Parâmetros: `param("usuario")` produzirá o valor do parâmetro se estiver disponível.

O primeiro caso é importante porque mostra o resultado da expressão regular.

No segundo caso, a _substring_ `:id` é substituída por `([^\\/]+)` e a _string_ se torna `"usuarios/([^\\/]+)"` antes de realizar a combinação. Assim, ela se converte para a primeira forma, como vimos acima.

No terceiro caso, para o símbolo, não importa o que ele representa, pois será substituído por `"([^\\/]+)"` e novamente entramos no primeiro caso.

O quarto caso, novamente, será convertido para um matcher básico: ele gera a _string_ `"([^\\/]+?)\.#{ext}\\z"` antes de realizar a combinação.

O quinto caso é diferente: ele checa se o parâmetro informado está presente na requisição (por meio de POST ou QUERY_STRING) e envia o valor como uma captura.

Composição
-----------

Você pode criar um aplicativo com o Cuba, juntamente com middlewares, dentro de outro aplicativo com Cuba.

``` ruby
class API < Cuba; end

API.use AlgumMiddleware

API.define do
  on param("url") do |url|
    ...
  end
end

Cuba.define do
  on "api" do
    run API
  end
end
```

Testes
-------

Considerando que o Cuba é essencialmente Rack, é muito fácil testar com `Rack::Test`, `Webrat` ou `Capybara`. Os próprios testes em Cuba são escritos com uma combinação de [Cutest][cutest] e [Rack::Test][rack-test]. Caso queira, use o `cuba/test`:

``` ruby
require "cuba/test"
require "pasta/aplicativo"

scope do
  test "Página inicial" do
    get "/"

    assert_equal "Olá mundo!", last_response.body
  end
end
```

Se preferir, use o [Capybara][capybara], chamando `cuba/capybara`:

``` ruby
require "cuba/capybara"
require "pasta/aplicativo"

scope do
  test "Página inicial" do
    visit "/"

    assert has_content?("Olá mundo!")
  end
end
```

Leia mais sobre testes, checando a documentação do [Cutest][cutest], [Rack::Test][rack-test] e [Capybara][capybara].

Configurações
--------

Cada aplicativo com Cuba pode armazenar configuração no hash `Cuba.settings`. As configurações são herdadas no momento em que usar a subclasse `Cuba`.

``` ruby
Cuba.settings[:layout] = "visitante"

class Usuarios < Cuba; end
class Admin < Cuba; end

Admin.settings[:layout] = "admin"

assert_equal "visitante", Usuarios.settings[:layout]
assert_equal "admin", Admin.settings[:layout]
```

Você pode armazenar o que achar conveniente.

Renderização
---------

Cuba possui um _plugin_ que oferece _helpers_ para renderizar _templates_. Ele usa o [Tilt][tilt], uma gem que oferece interfaces para diversos _template engines_.

``` ruby
require "cuba/render"

Cuba.plugin Cuba::Render

Cuba.define do
  on default do

    # Dentor da partial, você terá acesso a uma variável local chamada
    # `content`, contendo o valor "olá, mundo".
    res.write render("pagina.haml", content: "olá, mundo")
  end
end
```

Veja que, para usar este _plugin_, você precisa ter o [Tilt][tilt] instalado, juntamente com _template engines_ que deseja usar.

Plugins
-------

Cuba fornece uma forma de estender suas funcionalidades com _plugins_.

### Como criar plugins

Criar seus próprios _plugins_ é muito simples.

``` ruby
module MeuProprioHelper
  def promocao(str)
    PanoAzul.new(str).to_html
  end
end

Cuba.plugin MeuProprioHelper
```

Esse é um tipo simples de plugin que irá escrever. Na verdade, é exatamente assim que o _helper_ `promocao` será escrito em `Cuba::TextHelpers`.

Um _plugin_ mais elaborado pode fazer uso do `Cuba.settings` para fornecer valores padrão. No exemplo abaixo, veja que, se o módulo tem um `setup`, o método será chamado automaticamente quando for incluído.

``` ruby
module Render
  def self.setup(app)
    app.settings[:template_engine] = "erb"
  end

  def partial(template, locals = {})
    render("#{template}.#{settings[:template_engine]}", locals)
  end
end

Cuba.plugin Render
```

Este simples _plugin_ mostra como o `Cuba::Render` funciona.

Por fim, se o módulo `ClassMethods` estiver presente, `Cuba` será extendido com ele.

``` ruby
module GetSetter
  module ClassMethods
    def set(key, value)
      settings[key] = value
    end

    def get(key)
      settings[key]
    end
  end
end

Cuba.plugin GetSetter

Cuba.set(:foo, "bar")

assert_equal "bar", Cuba.get(:foo)
assert_equal "bar", Cuba.settings[:foo]
```

Instalação
------------

``` ruby
$ gem install cuba
```
