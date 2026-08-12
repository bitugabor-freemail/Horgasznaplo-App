void _teljesKepernyosKep(BuildContext context, Tura tura, String kepUtvonal, String helyszinNev) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                // Ikon cserélve Letöltésre
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () {
                  // Vízjeles Letöltő meghívása a helyszín nevével
                  VizjelKeszito.turaLetoltes(context, tura, kepUtvonal, helyszinNev);
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(kepUtvonal)),
            ),
          ),
        ),
      ),
    );
  }
