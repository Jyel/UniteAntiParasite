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

class UI
	def initialize
		@font = Gosu::Font.new(35, name: "media/font/Perfect DOS VGA 437 Win.ttf")
	end
	
	def draw(score, niveau, hp)
		@font.draw_rel("#{score}", 210, 7, 2, 0.5, 0, 1, 1, 0xff_ffffff)
		@font.draw_rel("#{niveau}", 36, 7, 2, 0.5, 0, 1.0, 1.0, 0xff_ffffff)
		hp.draw(350 - hp.width / 2, 610 - hp.height / 2, 2)
	end
end

class GameOver
	def initialize
		@bigfont = Gosu::Font.new(70, name: "media/font/Perfect DOS VGA 437 Win.ttf")
		@font = Gosu::Font.new(20, name: "media/font/Perfect DOS VGA 437 Win.ttf")
	end
	
	def draw(score, highscore)
		@bigfont.draw_rel("GAME OVER", 210, 100, 4, 0.5, 1.0, 1.0, 1.0, 0xff_ffffff)
		@font.draw_rel("Nouveau meilleur score !", 210, 125, 4, 0.5, 1.0, 1.0, 1.0, 0xff_ffbe1c) if score == highscore
		@font.draw_rel("Votre score : #{score}", 210, 175, 4, 0.5, 1.0, 1.0, 1.0, 0xff_ffffff)
		@font.draw_rel("Meilleur score : #{highscore}", 210, 200, 4, 0.5, 0.5, 1.0, 1.0, 0xff_ffffff)
	end
end

class Enemy
  attr_reader :y, :x
  
	def initialize()
		@enemy = Gosu::Image.new("media/ui/virus.png", retro: true)
		@x = rand * (420 - @enemy.width)
		@y = -500
	end
	
	def update(vitesse)
		@y += vitesse
	end
	
	def x_center_of_mass
		@x + @enemy.width / 2
	end
	
	def y_center_of_mass
		@y
	end
	
	def draw
		@enemy.draw(@x, @y, -1)
	end
end

class GameWindow < Gosu::Window
	DistanceofCollision = 35
	DistanceofCollisionPlayer = 50
	
	def initialize #Initialise les données et objets
		super 420,640
			#Initialisation des données
		self.caption = "UAP : Unité Anti-Parasite" #Titre de la fenêtre
		@toggleon = 0 #Démarre le jeu
		@gameover = 0
		@show_credits = 0 #Affiche les crédits
		@playclicked = 0 #Détermine si le bouton PLAY a été cliqué
		@songplay = 0 #Détermine quand la musique joue
		@vitesse = 8 #Détermine la vitesse horizontale du joueur
		@vitessedecor = 3
		@niveau = 1
		@e = Enemy.new
		@tir = 0 #Détermine quand le joueur tire
		@highscore = File.read("HIGHSCORE").to_i
			#Initialisation de la musique
		@son_img = Gosu::Image.new("media/ui/son_on.png", retro: true)
		@toggleson = 0
		@togglesontimer = 0
		@son = 1
		@loop = Gosu::Song.new("media/music/song_loop.ogg")
		@loop.volume = 0.25
		@loopstart = Gosu::Song.new("media/music/song_start.ogg")
		@loopstart.volume = 0.25
			#Initlialisation des sons
		@shootplay = 0;
		@shoot1 = Gosu::Sample.new("media/sound/shoot1.wav")
		@shoot2 = Gosu::Sample.new("media/sound/shoot2.wav")
		@shoot3 = Gosu::Sample.new("media/sound/shoot3.wav")
		@explosion = Gosu::Sample.new("media/sound/explosion.wav")
		@hit = Gosu::Sample.new("media/sound/hit.wav")
			#Initialisation du background et de ses coordonnées
		@background  = Gosu::Image.new("media/back/background.png", retro: true)
		@header = Gosu::Image.new("media/back/header.png", retro: true)
		@x1, @y1 = 0, 0
			#Initialisation du joueur et de ses coordonnées
		@laser = Gosu::Image.new("media/ui/laser.png", retro: true)
		@player = Gosu::Image.new("media/ui/ship.png", retro: true)
		@player_x, @player_y = 210 - (@player.width / 2), 620 - @player.height
		@laser_x, @laser_y = @player_x, @player_y
		@toggleshoot = 0
		@enemies = [] #Initialise la liste d'ennemis
			#Initialisation du menu play
		@title = Gosu::Image.new("media/back/title.png", retro: true)
		@cache = Gosu::Image.new("media/back/black.png", retro: true)
		@menu = Menu.new(self)
		@menu.add_item(Gosu::Image.new("media/button/play.png", retro: true), 210 - 150/2, 320 - 75/2, 3, lambda { 
			if @show_credits == 0 or (@gameover == 1 and @show_credits == 0)
				@show_credits = 0
				@gameover = 0
				@toggleon = 1
				@playclicked = 1
				@hp = Gosu::Image.new("media/ui/coeur1.png", retro: true)
				@score = 0 if @vie == 0
				@niveau = 1 if @vie == 0
				@vie = 3 if @vie == 0
			end
		}, Gosu::Image.new("media/button/play_hover.png", retro: true))
		@menu.add_item(Gosu::Image.new("media/button/credits.png", retro: true), 210 - 150/2, 420 - 75/2, 3, lambda {
			@show_credits = 1 if @toggleon == 0 or @gameover == 1
		}, Gosu::Image.new("media/button/credits_hover.png", retro: true))
		@menu.add_item(Gosu::Image.new("media/button/exit.png", retro: true), 210 - 150/2, 520 - 75/2, 3, lambda {
			close if (@toggleon == 0 or @gameover == 1) and @show_credits == 0
		}, Gosu::Image.new("media/button/exit_hover.png", retro: true))
			#Initialisation du UI
		@ui = UI.new
		@g_o = GameOver.new
		@hp = Gosu::Image.new("media/ui/coeur4.png", retro: true)
		@vie = 3
		@score = 0
		@scoremin = 1
		@scoreplus = 10 + @scoremin
			#Polices de caractères
		@basicfont = Gosu::Font.new(20, name: "media/font/Perfect DOS VGA 437 Win.ttf")
		@bigfont = Gosu::Font.new(50, name: "media/font/Perfect DOS VGA 437 Win.ttf")
		@smallfont = Gosu::Font.new(15, name: "media/font/Perfect DOS VGA 437 Win.ttf")
	end

	def update #60 fois par seconde
			#Ici je mets en place la musique de fond
		if @son == 1
			@son_img = Gosu::Image.new("media/ui/son_on.png", retro: true)
		else
			@son_img = Gosu::Image.new("media/ui/son_off.png", retro: true)
		end
		
		if button_down?(Gosu::KB_P) and @son == 1 and @toggleson == 0
			@son = 0
			@toggleson = 1
		elsif button_down?(Gosu::KB_P) and @son == 0 and @toggleson == 0
			@son = 1
			@toggleson = 1
		end
		
		if @toggleson == 1 and @togglesontimer <= 6
				@togglesontimer += 1
		end
		
		if @togglesontimer == 6
			@togglesontimer = 0
			@toggleson = 0
		end
		
		if @songplay == 0 and @toggleon == 1 and @gameover == 0
			@loopstart.play
			@songplay = 1
		end
		if @songplay == 1 and @loopstart.playing? == false
			@loop.play(true)
		end
			#Ici j'ai fait en sorte que si le joueur a mis le jeu sur pause, la musique diminue de volume
		if @toggleon == 0 and @songplay >= 1
			@loop.volume = 0.05 * @son
			@loopstart.volume = 0.05 * @son
		elsif @playclicked == 1 and @songplay >= 1
			@loop.volume = 0.25 * @son
		end
		
		@menu.update #Update le menu
		
		@niveau += 1 if @score >= @niveau * 1000
		@vitessedecor = 2 + @niveau
		
			#Toggle sert à démarrer le jeu seulement quand la barre play est cliqué
		if @toggleon ==  1 and @gameover == 0 #Dans cette boucle, mettre toutes les fonctions prévues
			@y1 += @vitessedecor
			@player_x -= @vitesse if button_down?(Gosu::KB_A) or button_down?(Gosu::KbLeft) and @player_x >= 0
			@player_x += @vitesse if button_down?(Gosu::KB_D) or button_down?(Gosu::KbRight) and @player_x < 420 - @player.width
			@laser_x = @player_x + @player.width / 2 - @laser.width / 2 if @tir == 0
			@laser_y = 620 - @laser.height if @tir == 0
			@laser_y -= 40 if @tir == 1
			@toggleon = 0 if button_down?(Gosu::KbSpace)
			@tir = 1 if button_down?(Gosu::KB_W) or button_down?(Gosu::KbUp)
			@tir = 0 if @laser_y <= 0 - @laser.height
			@shootplay = 0 if @laser_y <= 0 - @laser.height
			@toggleshoot = 0 if @tir == 0
			
			if @tir == 1 and @shootplay == 0
				if rand < 0.33
					@shoot1.play(1.0 * @son)
				elsif rand < 0.66
					@shoot2.play(1.0 * @son)
				else
					@shoot3.play(1.0 * @son)
				end
				@shootplay = 1
			end
			
			if @tir == 1
				@enemies.reject! {|enemy| collide?(enemy) ? collision : false}
			end
			
			@enemies.reject! {|enemy| collide_player?(enemy) ? collision_player : false}
			
			if @tir == 1 and @toggleshoot == 0 and @score >= @scoremin
				@toggleshoot = 1
				@score -= @scoremin
			end
			
			if @vie == 0
				@loop.stop
				@loopstart.stop
				@songplay = 0
				@gameover = 1
				@player_x, @player_y = 210 - (@player.width / 2), 620 - @player.height
				@enemies = []
				@hp = Gosu::Image.new("media/ui/coeur4.png", retro: true)
				if File.read("HIGHSCORE").to_i < @score
					File.write("HIGHSCORE", "#{@score}")
					@highscore = @score
				end
			end
			
			@hp = Gosu::Image.new("media/ui/coeur2.png", retro: true) if @vie == 2
			@hp = Gosu::Image.new("media/ui/coeur3.png", retro: true) if @vie == 1
			
			#Gère l'apparition des ennemis.
			unless @enemies.size >= 15
				r = rand
				if r < 0.2
					@enemies.push(Enemy.new())
				end
			end
			
			@enemies.each { |enemy|
				enemy.update(@vitessedecor)
			}
			@enemies.each{ |enemy|
				if enemy.y > 640 and @score >= @scoremin
					@score -= 20 * @scoremin if @score - 20 * @scoremin >= 0
					@score = 0 if @score - 20 * @scoremin < 0
				end
			}
			@enemies.reject! {|enemy| enemy.y > 640}
			
		else
		end
	end
	
	def collide?(enemy)
		distance = Gosu::distance(x_center_of_mass, y_center_of_mass, enemy.x_center_of_mass, enemy.y_center_of_mass)
		distance < DistanceofCollision
	end
	
	def collide_player?(enemy)
		distance = Gosu::distance(x_center_of_mass_player, y_center_of_mass_player, enemy.x_center_of_mass, enemy.y_center_of_mass)
		distance < DistanceofCollisionPlayer
	end
	
	def x_center_of_mass
		@laser_x + @laser.width / 2
	end
	
	def x_center_of_mass_player
		@player_x + @player.width / 2
	end
	
	def y_center_of_mass
		@laser_y + @laser.height / 4
	end
	
	def y_center_of_mass_player
		@player_y + @player.height / 4
	end
	
	def collision
		@score += @scoreplus
		@tir = 0
		@shootplay = 0
		@explosion.play(1.0 * @son)
		true
	end
	
	def collision_player
		@vie -= 1 if @vie > 0
		@hit.play(1.0 * @son)
	end
	
	def draw #Affiche (dessine) les objets
			#Affichage du menu
		if @toggleon == 0 or @gameover == 1
			@cache.draw(0, 0, 3)
			@menu.draw if @show_credits == 0
		end
		@title.draw(420/2 - (@title.width / 2), 125 - (@title.height / 2), 4)  if @show_credits == 0 and @gameover == 0 and @toggleon == 0
		
			#Affichage du UI
		@son_img.draw(420 - @son_img.width - 10, 5, 2)
		@ui.draw(@score, @niveau, @hp)
		@g_o.draw(@score, @highscore) if @gameover == 1 and @show_credits == 0
			#Affichage des crédits
		if @show_credits == 1
			@bigfont.draw_rel("<u>Crédits</u>",
                       420 / 2, 50,
					   3,
                       0.5, 0.5)
			@basicfont.draw_rel("<i>(c) 2017 Spé Informatique et</i>",
                       420 / 2, 115,
					   3,
                       0.5, 0.5)
			@basicfont.draw_rel("<i>Science du Numérique</i>",
                       420 / 2, 140,
					   3,
                       0.5, 0.5)
			@basicfont.draw_rel("<i>Lycée privé Blanche de Castille</i>",
                       420 / 2, 175,
					   3,
                       0.5, 0.5)
			@basicfont.draw_rel("<i>Tous droits réservés</i>",
                       420 / 2, 200,
					   3,
                       0.5, 0.5)
			@basicfont.draw_rel("<u>Programmation</u>",
                       420 / 2, 250,
					   3,
                       0.5, 0.5)
			@basicfont.draw_rel("Jean Louette",
                       420 / 2, 275,
					   3,
                       0.5, 0.5)
			@basicfont.draw_rel("Frédéric Ekima",
						420 / 2, 300,
						3,
						0.5, 0.5)
			@basicfont.draw_rel("<u>Graphismes</u>",
                       420 / 2, 350,
					   3,
                       0.5, 0.5)
			@basicfont.draw_rel("Jean Louette",
						420 / 2, 375,
						3,
						0.5, 0.5)
			@basicfont.draw_rel("<u>Musique</u>",
                       420 / 2, 425,
					   3,
                       0.5, 0.5)
			@basicfont.draw_rel("Martin Lugagne Delpon",
						420 / 2, 450,
						3,
						0.5, 0.5)
			@smallfont.draw_rel("Appuyez sur ← (effacer)",
                       420 / 2, 605,
					   3,
                       0.5, 0.5)
			@smallfont.draw_rel("pour retourner à l'écran principal",
                       420 / 2, 620,
					   3,
                       0.5, 0.5)
		end
			#Affichage du background
		@local_y = @y1 % -@background.height
		@background.draw(@x1, @local_y, -1)
		@background.draw(@x1, @local_y + @background.height, -1) if @local_y < (@background.height - self.height)
		@header.draw(0, 0, 1)
			#Affichage du joueur
		@player.draw(@player_x, @player_y, 1)
		@laser.draw(@laser_x, @laser_y, 0) if @tir == 1
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

window = GameWindow.new
window.show