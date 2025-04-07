# Funzione per eseguire un comando e controllarne l'esito
run_command() {
    "$@"
    if [ $? -ne 0 ]; then
        echo "Errore durante l'esecuzione del comando: $*"
        exit 1
    fi
}

usage() {
  echo "Utilizzo: $0 -e executable [-f functions_file] [-g globals_file]"
  echo "   -e executable     : Nome dell'eseguibile da processare (obbligatorio)."
  echo "   -f functions_file : File contenente i nomi delle funzioni da strippare (opzionale)."
  echo "   -g globals_file   : File contenente i nomi delle variabili globali da strippare (opzionale)."
  echo "   -h                : Mostra questo messaggio di aiuto."
  exit 1
}

# Parsing degli argomenti
while getopts ":e:f:g:h" opt; do
    case $opt in
        e)
            EXECUTABLE="$OPTARG"
            ;;
        f)
            FUNCTIONS_FILE="$OPTARG"
            ;;
        g)
            GLOBALS_FILE="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Opzione non valida: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "L'opzione -$OPTARG richiede un argomento." >&2
            usage
            ;;
    esac
done

# Verifica esistenza eseguibile
if [ -z "$EXECUTABLE" ]; then
    echo "Errore: l'eseguibile è obbligatorio."
    usage
fi

if [ ! -f "$EXECUTABLE" ]; then
    echo "Errore: l'eseguibile '$EXECUTABLE' non esiste."
    exit 1
fi

# Creazione backup dell'eseguibile
run_command cp "$EXECUTABLE" "${EXECUTABLE}.backup"

echo "=== Stato iniziale dei simboli ==="
if [ -n "$GLOBALS_FILE" ]; then
    echo "Variabili globali presenti:"
    run_command nm "$EXECUTABLE" | grep -f "$GLOBALS_FILE"
fi

if [ -n "$FUNCTIONS_FILE" ]; then
    echo -e "\nFunzioni presenti:"
    run_command nm "$EXECUTABLE" | grep -f "$FUNCTIONS_FILE"
fi

# Se non sono stati passati file per funzioni e globali, esegue uno strip completo
if [ -z "$GLOBALS_FILE" ] && [ -z "$FUNCTIONS_FILE" ]; then
    echo -e "\nNessun file di funzioni o variabili globali fornito, eseguo uno strip completo."
    run_command strip "$EXECUTABLE"
    echo "Strip completo effettuato. Backup salvato come ${EXECUTABLE}.backup"
    exit 0
fi

# Esecuzione dello strip per le variabili globali se il file è stato fornito
if [ -n "$GLOBALS_FILE" ]; then
    echo -e "\n=== Rimozione delle variabili globali ==="
    while read -r symbol; do
        # Salta eventuali righe vuote
        if [ -n "$symbol" ]; then
            echo "Rimozione del simbolo globale: $symbol"
            run_command strip --strip-symbol="$symbol" "$EXECUTABLE"
            run_command objcopy --strip-symbol="$symbol" "$EXECUTABLE" "$EXECUTABLE.tmp"
            run_command mv "$EXECUTABLE.tmp" "$EXECUTABLE"
        fi
    done < "$GLOBALS_FILE"
fi

# Esecuzione dello strip per le funzioni se il file è stato fornito
if [ -n "$FUNCTIONS_FILE" ]; then
    echo -e "\n=== Rimozione delle funzioni ==="
    while read -r symbol; do
        if [ -n "$symbol" ]; then
            echo "Rimozione della funzione: $symbol"
            run_command strip --strip-symbol="$symbol" "$EXECUTABLE"
            run_command objcopy --strip-symbol="$symbol" "$EXECUTABLE" "$EXECUTABLE.tmp"
            run_command mv "$EXECUTABLE.tmp" "$EXECUTABLE"
        fi
    done < "$FUNCTIONS_FILE"
fi

echo -e "\n=== Verifica finale ==="
if [ -n "$GLOBALS_FILE" ]; then
    echo "Verifica delle variabili globali rimanenti:"
    nm "$EXECUTABLE" | grep -f "$GLOBALS_FILE"
fi

if [ -n "$FUNCTIONS_FILE" ]; then
    echo -e "\nVerifica delle funzioni rimanenti:"
    nm "$EXECUTABLE" | grep -f "$FUNCTIONS_FILE"
fi

echo -e "\nProcesso completato. Backup salvato come ${EXECUTABLE}.backup"
