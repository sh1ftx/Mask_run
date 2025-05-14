-- main.lua

-- Definindo variáveis globais
local tileSize = 32
local player = {x = 100, y = 100, width = tileSize, height = tileSize, color = {0, 1, 1}}
local lavaLevel = 0
local map = {}
local traps = {}
local gameOver = false
local score = 0
local gameStarted = false

-- Controle de entrada por grid
local inputCooldown = 0.1
local timeSinceInput = 0

-- Paleta inspirada no estilo Tomb of the Mask
local colors = {
    background = {0.06, 0.06, 0.06},
    wall = {0.98, 0.91, 0.28},
    wallBorder = {1, 1, 1},
    lava = {1, 0.34, 0.2},
    trap = {1, 0.1, 0.1},
    player = {0, 1, 1},
    text = {1, 1, 1}
}

-- Carregar recursos
function love.load()
    love.graphics.setBackgroundColor(colors.background)
    love.audio.newSource("background_music.mp3", "stream"):play()

    generateMap()
    generateTraps()
end

-- Atualiza o estado do jogo
function love.update(dt)
    if gameOver then
        if love.keyboard.isDown("return") then
            restartGame()
        end
        return
    end

    if not gameStarted then
        if love.keyboard.isDown("return") then
            gameStarted = true
            lavaLevel = 0
            score = 0
            player.x, player.y = 100, 100
            timeSinceInput = 0
        end
        return
    end

    handlePlayerMovement(dt)

    lavaLevel = lavaLevel + dt * 20
    if lavaLevel >= love.graphics.getHeight() then
        gameOver = true
    end

    checkCollisions()
end

-- Lógica de movimento em grid
function handlePlayerMovement(dt)
    timeSinceInput = timeSinceInput + dt
    if timeSinceInput < inputCooldown then return end

    local dirX, dirY = 0, 0

    if love.keyboard.isDown("up") then dirY = -1
    elseif love.keyboard.isDown("down") then dirY = 1
    elseif love.keyboard.isDown("left") then dirX = -1
    elseif love.keyboard.isDown("right") then dirX = 1
    else return end

    local newX = player.x + dirX * tileSize
    local newY = player.y + dirY * tileSize

    if not checkWallCollision(newX, newY) then
        player.x, player.y = newX, newY
        timeSinceInput = 0
    end
end

-- Verifica colisão com paredes
function checkWallCollision(nextX, nextY)
    local mapX = math.floor(nextX / tileSize) + 1
    local mapY = math.floor(nextY / tileSize) + 1
    return map[mapX] and map[mapX][mapY] == 1
end

-- Geração do mapa do labirinto
function generateMap()
    for i = 1, 20 do
        map[i] = {}
        for j = 1, 20 do
            map[i][j] = math.random() < 0.2 and 1 or 0
        end
    end
end

-- Geração de armadilhas
function generateTraps()
    traps = {}
    for i = 1, 5 do
        local trap = {
            x = math.random(1, 19) * tileSize,
            y = math.random(1, 19) * tileSize,
            type = "spike"
        }
        table.insert(traps, trap)
    end
end

-- Desenha todos os elementos do jogo
function love.draw()
    if gameOver then
        love.graphics.setColor(colors.text)
        love.graphics.printf("GAME OVER\nScore: " .. score .. "\nPress ENTER to Restart", 0, 300, love.graphics.getWidth(), "center")
        return
    end

    if not gameStarted then
        love.graphics.setColor(colors.text)
        love.graphics.printf("Press ENTER to Start", 0, 300, love.graphics.getWidth(), "center")
        return
    end

    -- Desenha o mapa
    for i = 1, 20 do
        for j = 1, 20 do
            local x, y = (i - 1) * tileSize, (j - 1) * tileSize
            if map[i][j] == 1 then
                love.graphics.setColor(colors.wall)
                love.graphics.rectangle("fill", x, y, tileSize, tileSize)
                love.graphics.setColor(colors.wallBorder)
                love.graphics.rectangle("line", x, y, tileSize, tileSize)
            end
        end
    end

    -- Jogador
    love.graphics.setColor(colors.player)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)

    -- Lava
    love.graphics.setColor(colors.lava)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - lavaLevel, love.graphics.getWidth(), lavaLevel)

    -- Armadilhas
    for _, trap in ipairs(traps) do
        love.graphics.setColor(colors.trap)
        love.graphics.circle("fill", trap.x + 8, trap.y + 8, 8)
    end

    -- HUD
    love.graphics.setColor(colors.text)
    love.graphics.print("Score: " .. score, 10, 10)
end

-- Verificação de colisões
function checkCollisions()
    -- Colisão com armadilhas
    for _, trap in ipairs(traps) do
        if player.x + player.width > trap.x and player.x < trap.x + 16 and
           player.y + player.height > trap.y and player.y < trap.y + 16 then
            gameOver = true
        end
    end

    -- Colisão com a lava
    if player.y + player.height > love.graphics.getHeight() - lavaLevel then
        gameOver = true
    end

    -- Score baseado na altura da lava
    score = math.floor(lavaLevel / 50)
end

-- Reiniciar o jogo
function restartGame()
    gameStarted = false
    gameOver = false
    lavaLevel = 0
    score = 0
    player.x, player.y = 100, 100
    traps = {}
    generateMap()
    generateTraps()
end
