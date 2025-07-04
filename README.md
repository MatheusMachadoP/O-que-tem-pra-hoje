# O que tem pra hoje? 🍳

Um aplicativo Flutter que ajuda você a descobrir receitas incríveis usando os ingredientes que você tem em casa!

## 📱 Sobre o Projeto

O "O que tem pra hoje?" é um app de receitas que permite:
- Adicionar ingredientes que você tem disponível
- Buscar receitas baseadas nesses ingredientes
- Favoritar receitas para acesso rápido
- Visualizar detalhes completos das receitas
- Tradução automática de receitas do inglês para português

## ✨ Funcionalidades

- **🔍 Busca Inteligente**: Encontre receitas usando ingredientes específicos
- **❤️ Favoritos**: Salve suas receitas preferidas
- **🌐 Tradução Automática**: Receitas traduzidas para português usando IA
- **📱 Interface Intuitiva**: Design limpo e fácil de usar
- **💾 Cache Local**: Traduções salvas localmente para acesso offline
- **🎯 Sugestões Personalizadas**: Receitas sugeridas na tela inicial

## 🛠️ Tecnologias Utilizadas

- **Flutter**: Framework principal para desenvolvimento mobile
- **Dart**: Linguagem de programação
- **Spoonacular API**: Fonte de receitas e informações nutricionais
- **OpenAI API**: Tradução de conteúdo
- **Gemini API**: Processamento de texto e limpeza de HTML
- **SQLite**: Banco de dados local para cache de traduções
- **HTTP**: Requisições para APIs externas

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK instalado
- Dart SDK
- Android Studio ou VS Code
- Emulador/dispositivo Android ou iOS

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/oqtemprahoje.git
cd oqtemprahoje
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure as variáveis de ambiente:
Crie um arquivo `.env` na raiz do projeto:
```env
SPOONACULAR_API_KEY=sua_chave_spoonacular
OPENAI_API_KEY=sua_chave_openai
GEMINI_API_KEY=sua_chave_gemini
```

4. Execute o aplicativo:
```bash
flutter run
```

## 🔧 Configuração das APIs

### Spoonacular API
1. Acesse [Spoonacular](https://spoonacular.com/food-api)
2. Crie uma conta e obtenha sua API key
3. Adicione a chave no arquivo `.env`

### OpenAI API
1. Acesse [OpenAI](https://platform.openai.com/)
2. Crie uma conta e obtenha sua API key
3. Adicione a chave no arquivo `.env`

### Gemini API
1. Acesse [Google AI Studio](https://makersuite.google.com/)
2. Obtenha sua API key
3. Adicione a chave no arquivo `.env`

## 📁 Estrutura do Projeto

```
lib/
├── pages/
│   ├── splash_page.dart         # Tela de boas-vindas
│   ├── home_page.dart           # Tela principal
│   ├── recipe_page.dart         # Lista de receitas
│   └── recipe_detail_page.dart  # Detalhes da receita
├── services/
│   ├── translation_manager.dart         # Gerenciador de traduções
│   ├── translation_database_service.dart # Banco de dados local
│   ├── gemini_translation_service.dart   # Integração com o Gemini
│   ├── openai_translation_service.dart   # Integração com a OpenAI
│   └── favorites_service.dart           # Gerenciamento de favoritos
└── main.dart                    # Ponto de entrada do app
```

## 🎨 Design

O aplicativo utiliza uma paleta de cores verde, transmitindo frescor e naturalidade:
- **Verde Principal**: `#66BB6A`
- **Verde Secundário**: `#388E3C`
- **Fundo**: `#F9FFF8`

## 🔄 Fluxo do Usuário

1. **Splash Screen**: Tela de boas-vindas com animação
2. **Home**: Adicionar ingredientes e ver sugestões
3. **Busca**: Encontrar receitas baseadas nos ingredientes
4. **Detalhes**: Visualizar receita completa com tradução
5. **Favoritos**: Acesso rápido às receitas salvas
