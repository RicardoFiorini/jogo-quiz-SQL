-- Criação do banco de dados
CREATE DATABASE JogoQuiz;
USE JogoQuiz;

-- Tabela para armazenar informações dos usuários
CREATE TABLE Usuarios (
    usuario_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabela para armazenar perguntas do quiz
CREATE TABLE Perguntas (
    pergunta_id INT AUTO_INCREMENT PRIMARY KEY,
    pergunta TEXT NOT NULL,
    resposta_correta VARCHAR(100) NOT NULL,
    categoria VARCHAR(50),
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabela para armazenar tentativas de quiz dos usuários
CREATE TABLE Tentativas (
    tentativa_id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    pergunta_id INT NOT NULL,
    resposta_fornecida VARCHAR(100),
    resultado ENUM('Correta', 'Incorreta') NOT NULL,
    data_tentativa DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id) ON DELETE CASCADE,
    FOREIGN KEY (pergunta_id) REFERENCES Perguntas(pergunta_id) ON DELETE CASCADE
);

-- Índices para melhorar a performance
CREATE INDEX idx_usuario_email ON Usuarios(email);
CREATE INDEX idx_pergunta_categoria ON Perguntas(categoria);
CREATE INDEX idx_tentativa_usuario ON Tentativas(usuario_id);
CREATE INDEX idx_tentativa_pergunta ON Tentativas(pergunta_id);
CREATE INDEX idx_tentativa_resultado ON Tentativas(resultado);

-- View para visualizar o desempenho dos usuários em cada pergunta
CREATE VIEW ViewDesempenhoUsuarios AS
SELECT u.usuario_id, u.nome, p.pergunta_id, p.pergunta, 
       t.resposta_fornecida, t.resultado, t.data_tentativa
FROM Tentativas t
JOIN Usuarios u ON t.usuario_id = u.usuario_id
JOIN Perguntas p ON t.pergunta_id = p.pergunta_id;

-- Função para calcular a pontuação total de um usuário
DELIMITER //
CREATE FUNCTION CalcularPontuacao(usuario_id INT) RETURNS INT
BEGIN
    DECLARE pontuacao INT;
    SELECT COUNT(*) INTO pontuacao
    FROM Tentativas
    WHERE usuario_id = usuario_id AND resultado = 'Correta';
    RETURN pontuacao;
END //
DELIMITER ;

-- Trigger para validar a resposta fornecida
DELIMITER //
CREATE TRIGGER Trigger_ValidaResposta
BEFORE INSERT ON Tentativas
FOR EACH ROW
BEGIN
    DECLARE resposta_correta VARCHAR(100);
    SELECT resposta_correta INTO resposta_correta
    FROM Perguntas
    WHERE pergunta_id = NEW.pergunta_id;

    IF NEW.resposta_fornecida IS NULL OR NEW.resposta_fornecida = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A resposta fornecida não pode ser vazia';
    END IF;
END //
DELIMITER ;

-- Inserção de exemplo de usuários
INSERT INTO Usuarios (nome, email) VALUES 
('João Silva', 'joao.silva@example.com'),
('Maria Oliveira', 'maria.oliveira@example.com'),
('Carlos Pereira', 'carlos.pereira@example.com');

-- Inserção de exemplo de perguntas
INSERT INTO Perguntas (pergunta, resposta_correta, categoria) VALUES 
('Qual é a capital da França?', 'Paris', 'Geografia'),
('Qual é a soma de 2 + 2?', '4', 'Matemática'),
('Quem escreveu "Dom Casmurro"?', 'Machado de Assis', 'Literatura');

-- Inserção de exemplo de tentativas
INSERT INTO Tentativas (usuario_id, pergunta_id, resposta_fornecida, resultado) VALUES 
(1, 1, 'Paris', 'Correta'),
(1, 2, '5', 'Incorreta'),
(2, 1, 'Londres', 'Incorreta'),
(2, 3, 'Machado de Assis', 'Correta'),
(3, 2, '4', 'Correta');

-- Selecionar todas as tentativas e desempenho dos usuários
SELECT * FROM ViewDesempenhoUsuarios;

-- Calcular pontuação total do usuário 1
SELECT CalcularPontuacao(1) AS pontuacao_total;

-- Excluir uma tentativa
DELETE FROM Tentativas WHERE tentativa_id = 1;

-- Excluir uma pergunta (isso removerá todas as tentativas associadas)
DELETE FROM Perguntas WHERE pergunta_id = 1;

-- Excluir um usuário (isso falhará se o usuário tiver tentativas associadas)
DELETE FROM Usuarios WHERE usuario_id = 1;
