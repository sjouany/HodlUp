import { Flex, Text } from '@chakra-ui/react';
import Header from '../Header/Header';
import Footer from '../Footer/Footer';

const Layout = ({ children }) => {
    return (
        <Flex justifyContent="space-between" alignItems="center" direction="column" height="100vh">
            <Header />
            {children}
            <Footer />
        </Flex>
    )   
}

export default Layout;