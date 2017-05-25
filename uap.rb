require 'gosu'
require 'rubygems'

# class Object
  # def method_missing( name, *args )
    # puts "There is no method '##{name}' defined on #{self.class}, you dummy!"
  # end
# end

class Menu #créé un menu
    def initialize (window)
        @window = window
        @items = Array.new
    end

    def add_item (image, x, y, z, callback, hover_image = nil)
        item = MenuItem.new(@window, image, x, y, z, callback, hover_image)
        @items << item
        self
    end

    def draw
        @items.each do |i|
            i.draw
        end
    end

    def update
        @items.each do |i|
            i.update
        end
    end

    def clicked
        @items.each do |i|
            i.clicked
        end
    end
end

class MenuItem #gère les choix du menu
    HOVER_OFFSET = 1
    def initialize (window, image, x, y, z, callback, hover_image = nil)
        @window = window
        @main_image = image
        @hover_image = hover_image
        @original_x = @x = x
        @original_y = @y = y
        @z = z
        @callback = callback
        @active_image = @main_image
    end

    def draw
        @active_image.draw(@x, @y, @z)
    end

    def update
        if is_mouse_hovering then
            if !@hover_image.nil? then
                @active_image = @hover_image
            end

            @x = @original_x + HOVER_OFFSET
            @y = @original_y + HOVER_OFFSET
        else 
            @active_image = @main_image
            @x = @original_x
            @y = @original_y
        end
    end

    def is_mouse_hovering
        mx = @window.mouse_x
        my = @window.mouse_y

        (mx >= @x and my >= @y) and (mx <= @x + @active_image.width) and (my <= @y + @active_image.height)
    end

    def clicked
        if is_mouse_hovering then
            @callback.call
        end
    end
end

class Enemy
  attr_reader :y
	def initialize()
		@enemy = Gosu::Image.new("media/ui/virus.png", retro: true)
		@x = rand * (420 - @enemy.width)
		@y = -500
	end
	
	def update
		@y += 3
	end
	
	def draw
		@enemy.draw(@x, @y, -1)
	end
end

window = GameWindow.new
class Laser
attr_accessor :laser_x, :laser_y, :tir, :laser_height
 
	def initialize
		@img = Gosu::Image.new("media/ui/laser.png", retro: true)
		@x, @y = GameWindow.new.player_x, GameWindow.new.player_y
		@tir = 0 #Détermine quand le joueur tire
	end
	
	def update
		@x = @GameWindow.player_x + @GameWindow.player.width / 2 - @img.width / 2 if @tir == 0
		@y = 620 - @img.height if @tir == 0
		@y -= 40 if @tir == 1
		
		@tir = 1 if button_down?(Gosu::KB_W) or button_down?(Gosu::KbUp)
		@tir = 0 if @y <= 0 - @img.height
	end
	
	def draw
		@img.draw(@x, @y, 0) if @tir == 1
	end
end


class GameWindow < Gosu::Window
	def initialize #Initialise les données et objets
		super 420,640
			#Initialisation des données
		self.caption = "UAP : Unité Anti-Parasite" #Titre de la fenêtre
		@toggleon = 0 #Démarre le jeu
		@show_credits = 0 #Affiche les crédits
		@playclicked = 0 #Détermine si le bouton PLAY a été cliqué
		@songplay = 0 #Détermine quand la musique joue
		@vitesse = 8 #Détermine la vitesse horizontale du joueur
			#Initialisation de la musique
		@loop = Gosu::Song.new("media/music/song_loop.ogg")
		@loop.volume = 0.25
		@loopstart = Gosu::Song.new("media/music/song_start.ogg")
		@loopstart.volume = 0.25
			#Initlialisation des sons
		@shootplay = 0;
		@shoot1 = Gosu::Sample.new("media/sound/shoot1.wav")
		@shoot2 = Gosu::Sample.new("media/sound/shoot2.wav")
		@shoot3 = Gosu::Sample.new("media/sound/shoot3.wav")
			#Initialisation du background et de ses coordonnées
		@background  = Gosu::Image.new("media/back/background.png", retro: true)
		@x1, @y1 = 0, 0
			#Initialisation du joueur et de ses coordonnées
		@player = Gosu::Image.new("media/ui/ship.png", retro: true)
		@player_x, @player_y = 210 - (@player.width / 2), 620 - @player.height
		@enemies = [] #Initialise la liste d'ennemis
			#Initialisation du menu play
		@title = Gosu::Image.new("media/back/title.png", retro: true)
		@cache = Gosu::Image.new("media/back/black.png", retro: true)
		@menu = Menu.new(self)
		@menu.add_item(Gosu::Image.new("media/button/play.png", retro: true), 210 - 150/2, 320 - 75/2, 2, lambda { if @show_credits == 0 ; @toggleon = 1 ; @playclicked = 1 ; end}, Gosu::Image.new("media/button/play_hover.png", retro: true))
		@menu.add_item(Gosu::Image.new("media/button/credits.png", retro: true), 210 - 150/2, 420 - 75/2, 2, lambda { @show_credits = 1 if @toggleon == 0}, Gosu::Image.new("media/button/credits_hover.png", retro: true))
		@menu.add_item(Gosu::Image.new("media/button/exit.png", retro: true), 210 - 150/2, 520 - 75/2, 2, lambda { close if @toggleon == 0 && @show_credits == 0 }, Gosu::Image.new("media/button/exit_hover.png", retro: true))
			#Polices de caractères
		@basicfont = Gosu::Font.new(20, name: "media/font/Perfect DOS VGA 437 Win.ttf")
		@bigfont = Gosu::Font.new(50, name: "media/font/Perfect DOS VGA 437 Win.ttf")
		@smallfont = Gosu::Font.new(15, name: "media/font/Perfect DOS VGA 437 Win.ttf")
	end

	def update #60 fois par seconde
			#Ici je mets en place la musique de fond
		if @songplay == 0 and @toggleon == 1
			@loopstart.play
			@songplay = 1
		end
		if @songplay == 1 and @loopstart.playing? == false
			@loop.play(true)
		end
			#Ici j'ai fait en sorte que si le joueur a mis le jeu sur pause, la musique diminue de volume
		if @toggleon == 0 and @songplay >= 1
			@loop.volume = 0.05
			@loopstart.volume = 0.05
		elsif @playclicked == 1 and @songplay >= 1
			@loop.volume = 0.25
		end
		
		@menu.update #Update le menu
		
			#Toggle sert à démarrer le jeu seulement quand la barre play est cliqué
		if @toggleon ==  1 #Dans cette boucle, mettre toutes les fonctions prévues
			@y1 += 3
			@player_x -= @vitesse if button_down?(Gosu::KB_A) or button_down?(Gosu::KbLeft) and @player_x >= 0
			@player_x += @vitesse if button_down?(Gosu::KB_D) or button_down?(Gosu::KbRight) and @player_x < 420 - @player.width
			@toggleon = 0 if button_down?(Gosu::KbSpace)
			@shootplay = 0 if laser.y <= 0 - laser.img.height
			
			if laser.tir == 1 and @shootplay == 0
				if rand < 0.33
					@shoot1.play
				elsif rand < 0.66
					@shoot2.play
				else
					@shoot3.play
				end
				@shootplay = 1
			end
			
			#Gère l'apparition des ennemis.
			unless @enemies.size >= 15
				r = rand
				if r < 0.02
					@enemies.push(Enemy.new())
				end
			end
			@enemies.each(&:update)
			@enemies.reject! {|item| item.y > 640}
			
		else
		end
	end

	def draw #Affiche (dessine) les objets
			#Affichage du menu
		if @toggleon == 0
			@title.draw(420/2 - (@title.width / 2), 125 - (@title.height / 2), 3)  if @show_credits == 0
			@cache.draw(0, 0, 2)
			@menu.draw if @show_credits == 0
		end
			#Affichage des crédits
		if @show_credits == 1
			@bigfont.draw_rel("<u>Crédits</u>",
                       420 / 2, 50,
					   2,
                       0.5, 0.5)
			@basicfont.draw_rel("<i>(c) 2017 Spé Informatique et</i>",
                       420 / 2, 115,
					   2,
                       0.5, 0.5)
			@basicfont.draw_rel("<i>Science du Numérique</i>",
                       420 / 2, 140,
					   2,
                       0.5, 0.5)
			@basicfont.draw_rel("<i>Lycée privé Blanche de Castille</i>",
                       420 / 2, 175,
					   2,
                       0.5, 0.5)
			@basicfont.draw_rel("<i>Tous droits réservés</i>",
                       420 / 2, 200,
					   2,
                       0.5, 0.5)
			@basicfont.draw_rel("<u>Programmation</u>",
                       420 / 2, 250,
					   2,
                       0.5, 0.5)
			@basicfont.draw_rel("Jean Louette",
                       420 / 2, 275,
					   2,
                       0.5, 0.5)
			@basicfont.draw_rel("Frédéric Ekima",
						420 / 2, 300,
						2,
						0.5, 0.5)
			@basicfont.draw_rel("<u>Graphismes</u>",
                       420 / 2, 350,
					   2,
                       0.5, 0.5)
			@basicfont.draw_rel("Jean Louette",
						420 / 2, 375,
						2,
						0.5, 0.5)
			@basicfont.draw_rel("<u>Musique</u>",
                       420 / 2, 425,
					   2,
                       0.5, 0.5)
			@basicfont.draw_rel("Martin Lugagne Delpon",
						420 / 2, 450,
						2,
						0.5, 0.5)
			@smallfont.draw_rel("Appuyez sur ← (effacer)",
                       420 / 2, 605,
					   2,
                       0.5, 0.5)
			@smallfont.draw_rel("pour retourner à l'écran principal",
                       420 / 2, 620,
					   2,
                       0.5, 0.5)
		end
			#Affichage du background
		@local_y = @y1 % -@background.height
		@background.draw(@x1, @local_y, -1)
		@background.draw(@x1, @local_y + @background.height, -1) if @local_y < (@background.height - self.height)
			#Affichage du joueur
		@player.draw(@player_x, @player_y, 1)
		@enemies.each(&:draw)
	end
	  
	def button_down(id) #Permet de donner des fonctions aux pressions de touches
		if id == Gosu::MsLeft then #Créé un clique dans le menu lors d'une pression du clic gauche
			@menu.clicked
		else
			super
		end
		
		if @show_credits == 1 and id == Gosu::KbBackspace
			@show_credits = 0
		end

	end
	
	def needs_cursor?
		true
	end
end

laser = Laser.new

window.show