# media_collector

Controle local de arquivos de media, com foco em filme se séries.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


media_manager/  
├── lib/  
│   ├── core/  
│   │   ├── constants/       # Cores, estilos, strings, tamanhos  
│   │   ├── utils/           # Helpers, extensions, formatters  
│   │   ├── errors/          # Exceções customizadas  
│   │   └── routes/          # Rotas nomeadas (se necessário)  
│   │  
│   ├── data/                # Camada de dados  
│   │   ├── datasources/     # Local (FileSystem) ou APIs futuras  
│   │   ├── models/          # Entidades (Movie, Serie, Folder)  
│   │   └── repositories/    # Implementações dos repositórios  
│   │  
│   ├── domain/              # Lógica de negócios  
│   │   ├── entities/        # Classes puras (ex: MediaFile)  
│   │   ├── repositories/    # Contratos (interfaces)  
│   │   └── usecases/        # Regras (GetMovies, ScanFolder)  
│   │  
│   └── presentation/        # UI e controle  
│       ├── pages/           # Telas (Home, Details, Settings)  
│       ├── widgets/         # Componentes reutilizáveis  
│       ├── providers/       # (ou bloc/cubit) para estado  
│       └── theme/           # Temas customizados  
│  
├── assets/  
│   ├── icons/               # Ícones do app  
│   └── images/              # Imagens padrão (capa de mídia fallback)  
│  
└── windows/                 # Configurações específicas do Windows  