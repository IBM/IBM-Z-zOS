#include <iostream>
#include <fcntl.h>
#include <_Nascii.h>

bool autoConversionStateIsOff() {
  return  (_CVTSTATE_OFF == __ae_autoconvert_state(_CVTSTATE_QUERY));
}

int main()
{
  std::cout << "Hello World\n";
  std::cout << "Auto-conversion is ";
  if (autoConversionStateIsOff())
    std::cout << "OFF\n";
  else
    std::cout << "ON\n";
  return 55;
}
