FROM    rakudo-star

COPY    META6.json /root
WORKDIR /root
RUN     zef install --depsonly .
COPY    . /root
