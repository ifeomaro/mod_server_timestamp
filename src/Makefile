NAME := mod_server_timestamp
SRC := $(wildcard *.erl)
BEAM := $(wildcard *.beam)
ERLC := erlc
INC := -I ${EJABBERD_PATH} -W0

all: $(NAME)

$(NAME): 
        $(ERLC) $(INC) $(SRC)

install: $(NAME)
        sudo cp $(BEAM) /lib/ejabberd/ebin/

restart: install
        sudo ejabberdctl restart

clean:
        rm -rf $(BEAM)

