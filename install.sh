
if [ -z $1 ]
then
  TARGET_PATH=/usr/local/bin
else
  TARGET_PATH=$1
fi

PERLPATH=$(which perl)

if [ -z $PERLPATH ]
then
  echo "Perl executable was not found"
  echo "Install Perl first, then try again."
  exit 1
fi

echo "Copying apertium-eval-translator in $TARGET_PATH"

echo -n "#!" > apertium-eval-translator
echo "$PERLPATH -w " >> apertium-eval-translator
cat eval-translator.pl >> apertium-eval-translator
chmod +x apertium-eval-translator

cp apertium-eval-translator $TARGET_PATH

if [ $? -eq 0 ]
then
  echo "apertium-eval-translator successfully installed"
else
  echo "Installation failed. Are you root?"  
fi

exit 0
