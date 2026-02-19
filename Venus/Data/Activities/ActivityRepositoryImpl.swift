//
//  ActivityRepositoryImpl.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

class ActivityRepositoryImpl: ActivityRepositoryProtocol {
    func getActivities() async -> [Activity] {
        return [
                    // MARK: - Relaxation (Destress)
                    Activity(
                        title: "Respiração 4-7-8",
                        description: "Técnica poderosa para acalmar o sistema nervoso em minutos.",
                        category: .relaxation,
                        durationMinutes: 5,
                        iconName: "lungs.fill",
                        steps: [
                            "Sente-se confortavelmente com a coluna ereta",
                            "Inspire pelo nariz silenciosamente contando até 4",
                            "Segure a respiração contando até 7",
                            "Expire completamente pela boca fazendo um som de sopro, contando até 8",
                            "Repita o ciclo por 4 vezes"
                        ],
                        targetEmotions: [.stressed, .sad]
                    ),
                    Activity(
                        title: "Técnica de Grounding",
                        description: "Exercício 5-4-3-2-1 para trazer você de volta ao momento presente.",
                        category: .relaxation,
                        durationMinutes: 5,
                        iconName: "eye.fill",
                        steps: [
                            "Respire fundo e olhe ao seu redor",
                            "Identifique 5 coisas que você pode ver",
                            "Identifique 4 coisas que você pode tocar",
                            "Identifique 3 coisas que você pode ouvir",
                            "Identifique 2 coisas que você pode cheirar",
                            "Identifique 1 coisa que você pode saborear ou sentir"
                        ],
                        targetEmotions: [.stressed, .sad]
                    ),
                    Activity(
                        title: "Yoga Nidra",
                        description: "Relaxamento profundo consciente para resetar mente e corpo.",
                        category: .relaxation,
                        durationMinutes: 20,
                        iconName: "bed.double.fill",
                        audioUrl: "yoga_nidra_track", // Placeholder for future audio
                        targetEmotions: [.stressed, .sad]
                    ),
                    Activity(
                        title: "Escaneamento Corporal",
                        description: "Meditação mindfulness para liberar tensão física progressivamente.",
                        category: .relaxation,
                        durationMinutes: 10,
                        iconName: "figure.mind.and.body",
                        steps: [
                            "Deite-se confortavelmente de costas",
                            "Leve sua atenção para os dedos dos pés",
                            "Note qualquer tensão e solte-a conscientemente",
                            "Suba lentamente para pernas, quadril e tronco",
                            "Relaxe os ombros, braços e mãos",
                            "Finalize relaxando o maxilar e a testa"
                        ],
                        targetEmotions: [.stressed, .sad]
                    ),
                    Activity(
                        title: "Sons da Natureza",
                        description: "Imersão auditiva em floresta tropical para reduzir cortisol.",
                        category: .relaxation,
                        durationMinutes: 15,
                        iconName: "tree.fill",
                        audioUrl: "nature_sounds_track",
                        targetEmotions: [.stressed, .sad]
                    ),
                    
                    // MARK: - Focus (Productivity)
                    Activity(
                        title: "Método Pomodoro",
                        description: "Ciclos de foco intenso de 25min para máxima produtividade.",
                        category: .focus,
                        durationMinutes: 25,
                        iconName: "timer",
                        steps: [
                            "Escolha uma tarefa única para focar",
                            "Elimine todas as distrações (celular, abas extras)",
                            "Trabalhe intensamente por 25 minutos",
                            "Pare imediatamente quando o tempo acabar",
                            "Faça um intervalo curto de 5 minutos"
                        ],
                        targetEmotions: [.calm, .happy]
                    ),
                    Activity(
                        title: "Deep Work Session",
                        description: "Bloco de trabalho profundo sem distrações. Desligue notificações.",
                        category: .focus,
                        durationMinutes: 60,
                        iconName: "brain.head.profile",
                        targetEmotions: [.happy, .calm]
                    ),
                    Activity(
                        title: "Binaural Beats",
                        description: "Frequências sonoras para aumentar concentração e clareza mental.",
                        category: .focus,
                        durationMinutes: 30,
                        iconName: "headphones",
                        audioUrl: "binaural_focus_track",
                        targetEmotions: [.calm, .tired]
                    ),
                    Activity(
                        title: "Planejamento Diário",
                        description: "Organize suas prioridades top 3 para o dia seguinte.",
                        category: .focus,
                        durationMinutes: 10,
                        iconName: "list.bullet.clipboard",
                        steps: [
                            "Revise o que foi feito hoje",
                            "Identifique as 3 tarefas mais importantes para amanhã",
                            "Anote-as em ordem de prioridade",
                            "Visualize-se completando cada uma delas"
                        ],
                        targetEmotions: [.stressed, .calm]
                    ),
                    
                    // MARK: - Creativity (Inspiration)
                    Activity(
                        title: "Morning Pages",
                        description: "Escrita livre sem julgamento para destravar criatividade.",
                        category: .creativity,
                        durationMinutes: 15,
                        iconName: "pencil.and.scribble",
                        steps: [
                            "Pegue caderno e caneta (preferencialmente à mão)",
                            "Escreva 3 páginas (ou 15 min) sem parar",
                            "Escreva qualquer coisa que vier à mente, sem filtro",
                            "Não se preocupe com gramática ou sentido",
                            "Se não souber o que escrever, escreva 'não sei o que escrever' até surgir algo"
                        ],
                        targetEmotions: [.calm, .sad]
                    ),
                    Activity(
                        title: "Caminhada Sem Destino",
                        description: "Deixe a mente vagar enquanto caminha para gerar novas ideias.",
                        category: .creativity,
                        durationMinutes: 20,
                        iconName: "figure.walk",
                        targetEmotions: [.stressed, .calm]
                    ),
                    Activity(
                        title: "Mind Mapping",
                        description: "Visualização livre de conexões para resolver problemas complexos.",
                        category: .creativity,
                        durationMinutes: 10,
                        iconName: "network",
                        targetEmotions: [.stressed, .calm]
                    ),
                    
                    // MARK: - Physical (Energy)
                    Activity(
                        title: "HIIT Rápido",
                        description: "Treino intervalado de alta intensidade para energia instantânea.",
                        category: .physical,
                        durationMinutes: 7,
                        iconName: "figure.run",
                        steps: [
                            "30s Polichinelos",
                            "15s Descanso",
                            "30s Agachamentos",
                            "15s Descanso",
                            "30s Flexões (ou joelhos no chão)",
                            "15s Descanso",
                            "30s Corrida no lugar",
                            "Repita o circuito 2 vezes"
                        ],
                        targetEmotions: [.tired, .calm, .stressed]
                    ),
                    Activity(
                        title: "Alongamento Consciente",
                        description: "Libere tensões físicas e mentais suavemente.",
                        category: .physical,
                        durationMinutes: 10,
                        iconName: "figure.flexibility",
                        steps: [
                            "Gire os ombros para trás 10 vezes",
                            "Incline a cabeça para a direita e segure por 15s",
                            "Incline a cabeça para a esquerda e segure por 15s",
                            "Estique os braços para cima e cresça a coluna",
                            "Toque os dedos dos pés (ou onde alcançar) e relaxe o pescoço"
                        ],
                        targetEmotions: [.stressed, .tired, .sad]
                    ),
                    Activity(
                        title: "Caminhada ao Sol",
                        description: "Exposição à luz natural para regular o ciclo circadiano.",
                        category: .physical,
                        durationMinutes: 15,
                        iconName: "sun.max.fill",
                        targetEmotions: [.sad, .tired]
                    ),
                    
                    // MARK: - Social (Connection)
                    Activity(
                        title: "Meditação da Bondade",
                        description: "Cultive compaixão por si mesmo e pelos outros.",
                        category: .social,
                        durationMinutes: 10,
                        iconName: "heart.circle",
                        steps: [
                            "Feche os olhos e pense em alguém que você ama",
                            "Deseje mentalmente: 'Que você seja feliz, que tenha saúde'",
                            "Pense em si mesmo e repita os desejos",
                            "Pense em uma pessoa neutra e repita",
                            "Finalize enviando essa energia para o mundo todo"
                        ],
                        targetEmotions: [.sad, .stressed]
                    ),
                    Activity(
                        title: "Gratidão Compartilhada",
                        description: "Envie uma mensagem agradecendo alguém importante.",
                        category: .social,
                        durationMinutes: 2,
                        iconName: "envelope.fill",
                        steps: [
                            "Pense em alguém que te ajudou recentemente",
                            "Escreva uma mensagem curta e sincera",
                            "Seja específico sobre o que você agradece",
                            "Envie sem esperar resposta imediata"
                        ],
                        targetEmotions: [.sad, .stressed]
                    ),
                    Activity(
                        title: "Diário de Gratidão",
                        description: "Três coisas boas que aconteceram hoje.",
                        category: .social, // Placing in social/emotional bucket
                        durationMinutes: 5,
                        iconName: "book.fill",
                        steps: [
                            "Respire fundo e reflita sobre o dia",
                            "Anote uma coisa simples que te fez sorrir",
                            "Anote uma conquista, mesmo que pequena",
                            "Anote uma pessoa ou momento especial",
                            "Sinta a emoção positiva de cada memória"
                        ],
                        targetEmotions: [.sad, .stressed, .calm]
                    )
                ]
    }
}