/* The DOS runtime folds ASCII uppercase and passes other integers through. */
int tolower(int character)
{
    if (character >= 'A' && character <= 'Z')
        character += 'a' - 'A';
    return character;
}
