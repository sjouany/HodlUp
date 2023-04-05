import { Button } from "@chakra-ui/react";

function ButtonDCA(props) {
  return (
    <Button 
    onClick={props.handleClick}
    backgroundColor="#28DA98"
    color="black"
    fontWeight="bold"
    size="lg"
    _hover={{ backgroundColor: "#22ba8a" }}
   // isLoading
    >
      {props.label}
    </Button>
  );
}

export default ButtonDCA;

