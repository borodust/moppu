; Set window properties
(gamekit:defgame :the-game () 
  ()
  (:viewport-width 800)           ; window's width
  (:viewport-height 600)          ; window's height
  (:viewport-title "The Game")    ; window's title
  (:draw-rate 60)
  (:act-rate 60))

; Load assets
(gamekit:register-resource-package :keyword "assets/")

(gamekit:define-image :player-right "moppy-right.png")
(gamekit:define-image :player-left  "moppy-left.png")
(gamekit:define-image :player-front "moppy-front.png")

(gamekit:define-image :block "block.png")
(gamekit:define-image :clouds "clouds.png")
(gamekit:define-image :background "background.png")

(gamekit:define-image :letter-m "menu/letter-m.png")
(gamekit:define-image :letter-o "menu/letter-o.png")
(gamekit:define-image :letter-p "menu/letter-p.png")
(gamekit:define-image :letter-u "menu/letter-u.png")
(gamekit:define-image :under-text "menu/under-text.png")
(gamekit:define-image :menu-bg "menu/menu-bg.png")
(gamekit:define-image :menu-f-1 "menu/menu-flower-1.png")
(gamekit:define-image :menu-f-2 "menu/menu-flower-2.png")
(gamekit:define-image :menu-f-3 "menu/menu-flower-3.png")

; Start the game loop
(gamekit:start :the-game)

(defvar *debug* nil)

; player vars
(defvar *player-position* (gamekit:vec2 400 100))
(defvar *move-dir* 0)
(defvar *velocity* 0)
(defvar *grounded* t)
(defvar *speed* 2)

;; scene vars
(defvar *clouds-one-pos-x* 0)
(defvar *clouds-two-pos-x* 800)

;; menu vars
(defvar *letter-padding* 210)
(defvar *letter-move* 0)
(defvar *transitioning* nil)
(defvar *alpha* 0)

(defvar *game-state* 0) ; 0- menu, 1- game, 2- credits

; Methods
(defun update-position ()
  (setf (gamekit:x *player-position*) (+ (* *move-dir* *speed*) (gamekit:x *player-position*)))
  (incf (gamekit:y *player-position*) *velocity*))

(defun real-time-seconds ()
  "Return seconds since certain point of time"
  (/ (get-internal-real-time) internal-time-units-per-second))

(defun moving-height (letter-height init-value)
  (+ letter-height (* 5 (sin (+ *letter-move* init-value)))))

; Game logic
(defmethod gamekit:draw ((app :the-game))
  (case *game-state* 
    (0 
      (gamekit:draw-image (gamekit:vec2 0 0) :menu-bg)
      (gamekit:draw-image (gamekit:vec2 310 520) :under-text)
      (gamekit:draw-image (gamekit:vec2 *letter-padding* (moving-height 400 0)) :letter-m)
      (gamekit:draw-image (gamekit:vec2 (+ *letter-padding* 110) (moving-height 390 20)) :letter-o)
      (gamekit:draw-image (gamekit:vec2 (+ *letter-padding* 180) (moving-height 360 40)) :letter-p)
      (gamekit:draw-image (gamekit:vec2 (+ *letter-padding* 250) (moving-height 360 10)) :letter-p)
      (gamekit:draw-image (gamekit:vec2 (+ *letter-padding* 320) (moving-height 390 50)) :letter-u)
      
      (gamekit:draw-image (gamekit:vec2 0 (moving-height -20 10)) :menu-f-1)
      (gamekit:draw-image (gamekit:vec2 0 (moving-height -30 20)) :menu-f-2)
      (gamekit:draw-image (gamekit:vec2 0 (moving-height -10 10)) :menu-f-3)
    )

    (1
      (gamekit:draw-image (gamekit:vec2 0 0) :background)
      (gamekit:draw-image (gamekit:vec2 *clouds-one-pos-x* 430) :clouds)
      (gamekit:draw-image (gamekit:vec2 *clouds-two-pos-x* 430) :clouds)

      (case *move-dir* 
        (1  (gamekit:draw-image *player-position* :player-right))
        (-1 (gamekit:draw-image *player-position* :player-left))
        (0  (gamekit:draw-image *player-position* :player-front)))

      ;(gamekit:draw-image (gamekit:vec2 100 110) :block) ;100 - 130, 110, 140
    )

    (2 ())
  )
  
  (gamekit:draw-rect (gamekit:vec2 0 0) 800 600 :fill-paint (gamekit:vec4 0 0 0 *alpha*))
  (when *debug*
    (gamekit:print-text (write-to-string *move-dir*) 10 590)
    (gamekit:print-text (write-to-string (gamekit:x *player-position*)) 10 570)
    (gamekit:print-text (write-to-string *transitioning*) 10 550)
    (gamekit:print-text (write-to-string *alpha*) 10 530)
    (gamekit:print-text (write-to-string *game-state*) 10 510)
    (gamekit:print-text (write-to-string *grounded*) 10 490)
    (gamekit:print-text (write-to-string *velocity*) 10 470))
)

(defmethod gamekit:act ((app :the-game))
  (case *game-state*
    (0 
      (setf *letter-move* (* 2 (real-time-seconds)))
      (if *transitioning* 
        (incf *alpha* 0.02))
      (if (>= *alpha* 1)
        (setf *game-state* 1))
    )
    
    (1
      (if *transitioning* 
        (decf *alpha* 0.02))
      (if (<= *alpha* 0)
        (setf *transitioning* nil))

      (if (not *grounded*) (decf *velocity* 0.2))

      (when (< (gamekit:y *player-position*) 100) 
        (setf *velocity* 0)
        (setf *grounded* t)
        (setf (gamekit:y *player-position*) 100))
      
      (update-position)
      (if (< *clouds-one-pos-x* -800) (setf *clouds-one-pos-x* 0))
      (decf *clouds-one-pos-x* 0.3)
      (if (< *clouds-two-pos-x* 0) (setf *clouds-two-pos-x* 800))
      (decf *clouds-two-pos-x* 0.3)
    )

    (2 ())
  )
)

; Input bindings
(gamekit:bind-button :a :pressed
  (lambda () (setf *move-dir* -1)))

(gamekit:bind-button :a :released
  (lambda () (setf *move-dir* 0)))

(gamekit:bind-button :d :pressed
  (lambda () (setf *move-dir* 1)))

(gamekit:bind-button :d :released
  (lambda () (setf *move-dir* 0)))

(gamekit:bind-button :space :pressed
  (lambda () 
    (case *game-state* 
      (0 
        (setf *transitioning* t)
      )
      
      (1 
          (when *grounded* 
            (setf *velocity* 5)
            (setf *grounded* nil))
      )
      
      (2 ())
    ) 
  )
)
